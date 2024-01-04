# Copyright 2018 Amazon.com, Inc. or its affiliates.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#    http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

# Function handles management of EC2 instances termination in relation to ECS clusters
#

import boto3
import requests
from botocore.exceptions import ClientError
import json
import base64
import re
import os
from datetime import datetime, time

_image_does_not_exist_action = os.getenv("IMAGE_DOES_NOT_EXIST_ACTION", "NO_ACTION")
_image_digest_not_found_action = os.getenv("IMAGE_DIGEST_NOT_FOUND_ACTION", "NO_ACTION")
_cluster_unstable_action = os.getenv("CLUSTER_UNSTABLE_ACTION", "NO_ACTION")
_dynamodb_tracking = os.getenv("DYNAMODB_TRACKING_TABLE", None)

def should_we_notify(dyn_c, unique_id):
    """
    Queries dynamodb to determine if a notification has already been sent based on unique_id. If no entry or TTL passed will return true otherwise false.
    """
    response = dyn_c.get_item(
        TableName=_dynamodb_tracking,
        Key={
            'UniqueId': {
                'S':unique_id
            }
        }
    )
    try:
        if round(datetime.datetime.now().timestamp()) < int(response['Item']['TimeToExist']['S']):
            return False
        else:
            return True
    except KeyError:
        return True

def tracking_update(dyn_c, unique_id):
    """
    Creates entry in Dynamodb with unique_id specified with a TTL of now + 1 hour.
    """
    response = dyn_c.put_item(
    TableName=_dynamodb_tracking,
    Item={
        'UniqueId':
        {
            'S':unique_id
        },
        'TimeToExist':
        {
            'S':(str(round(datetime.datetime.now().timestamp() + datetime.timedelta(hours=1).total_seconds())))
        }
    })

def notify_teams(message, public=False):
    """
    Function to send a message into Microsoft Teams using the requests library.

    Requires environment variables:
    - TEAMS_WEBHOOK_URL_PUBLIC
    - TEAMS_WEBOOK_URL_PRIVATE

    These environment variables must be set with a VALID webhook for 365
    """
    data = json.dumps({"text": message})
    _teams_webhook_url_public = os.getenv("TEAMS_WEBHOOK_URL_PUBLIC", None)
    _teams_webhook_url_private = os.getenv("TEAMS_WEBHOOK_URL_PRIVATE", None)
    if public and _teams_webhook_url_public is not None:
        requests.post(url=_teams_webhook_url_public, data=data)

    if _teams_webhook_url_private is not None and (_teams_webhook_url_private != _teams_webhook_url_public or not public):
        requests.post(url=_teams_webhook_url_private, data=data)

def verify_images(ecr_c, ecs_c, dyn_c, cluster_name):
    """
    Determines image in use for every task in the selected ECS Cluster and verifies it exists in ECR.
    """
    paginator = ecs_c.get_paginator('list_services')
    services = paginator.paginate(
        cluster=cluster_name,
        PaginationConfig={
            "PageSize": 100
        }
    )
    for page in services:
        for service in page['serviceArns']:
            response = (ecs_c.describe_services(
                cluster=cluster_name,
                services=[
                    service
                ]
            ))['services'][0]
            if response['desiredCount'] > 0:
                #print(response['taskDefinition'])
                response = ecs_c.describe_task_definition(
                    taskDefinition=response['taskDefinition'],
                )

                for container in response['taskDefinition']['containerDefinitions']:
                    image = container["image"]

                    # we dont verify anything that's not ecr
                    if "ecr" in image:
                        if not check_image_exists(ecr_c, image):
                            print(f'[CRITICAL] Image {image} could not be found. {service} will be unable to restart.')
                            remediate_service(ecs_c, dyn_c, cluster_name, service, additional_info=f'Missing image: {image}')

def remediate_service(ecs_c, dyn_c, cluster_name, service, additional_info=""):
    """
    Function to remediate service based on environment variables
    """

    if _image_does_not_exist_action == "STOP_SERVICE":
        response = ecs_c.describe_services(
            cluster=cluster_name,
            services=[service],
        )
        if response["services"][0]["desiredCount"] > 0:
            print(f'Service {service} is being stopped due to a missing docker image.')
            tracking_id = f'{cluster_name}-{service}-missing-image'
            if should_we_notify(dyn_c, unique_id=tracking_id):
                tracking_update(dyn_c, unique_id=tracking_id)
                notify_teams(f'[ECS Cluster: {cluster_name}] Service {service} has been stopped due to a missing docker image. {additional_info}', public=True)
            ecs_c.update_service(
                cluster=cluster_name,
                service=service,
                desiredCount=0)
    else:
        print(f'Service {service} has a missing docker image and is blocking the termination of the instance.')
        tracking_id = f'{cluster_name}-{service}-missing-image'
        if should_we_notify(dyn_c, unique_id=tracking_id):
            tracking_update(dyn_c, unique_id=tracking_id)
            notify_teams(f'[ECS Cluster: {cluster_name}] CRITICAL: Service {service} has a missing docker image and is blocking the termination of the instance.   \nMANUAL INTERVENTION REQUIRED   \n{additional_info}')

def check_image_exists(ecr_c, image, imagedigest=None):
    """
    Verify image exists in ECR returning boolean response.
    """
    if imagedigest is not None:
        imageIds = [{'imageDigest': imagedigest,'imageTag': image.split(':')[1]}]
    else:
        imageIds = [{'imageTag': image.split(':')[1]}]
    try:
        response = ecr_c.describe_images(
            repositoryName=(image.split('/')[1]).split(':')[0],
            imageIds=imageIds
        )
        return True
    except ClientError as error:
        return False

def find_cluster_name(ec2_c, instance_id):

    """
    Provided an instance that is currently, or should be part of an ECS cluster
    determines the ECS cluster name.  This is derived from the user-data
    which contains a command to inject the cluster name into ECS agent config
    files.

    On failure we raise an exception which means this instance isn't a ECS
    cluster member so we can proceed with termination.
    """

    try:
        response = ec2_c.describe_instance_attribute(
            InstanceId=instance_id,
            Attribute='userData'
        )
    except ClientError as e:
        raise e

    userdata = base64.b64decode(response['UserData']['Value']).decode('unicode_escape')

    clustername = re.search("ECS_CLUSTER\s?=\s?(.*?)\s", str(userdata))
    if clustername:
        return(clustername.group(1).strip("'"))

    raise(ValueError(
        "Unable to determine the ECS cluster name from instance metadata"
    ))


def find_container_instance_id(ecs_c, cluster_name, instance_id):

    """
    Given an ec2 instance ID determines the cluster instance ID.
    The ec2 instance ID and cluster instance ID aren't the same thing.
    Calls to the ECS control plane require the cluster instance ID.

    I haven't found a 'filter' way to do this so we're left listing
    all container instances and comparing against the known ec2
    instance id.

    On failure we raise an exception which means this instance isn't a ECS
    cluster member so we can proceed with termination.
    """

    paginator = ecs_c.get_paginator('list_container_instances')
    instances = paginator.paginate(
        cluster=cluster_name,
        PaginationConfig={
            "PageSize": 10
        }
    )

    for instance in instances:
        response = ecs_c.describe_container_instances(
            cluster=cluster_name,
            containerInstances=instance["containerInstanceArns"]
        )

        for container_instance in response["containerInstances"]:
            if container_instance["ec2InstanceId"] == instance_id:
                return(container_instance["containerInstanceArn"])

    raise(ValueError(
        "Unable to determine the ECS Container Instance ID"
    ))


def find_hook_duration(asg_c, asg_name, instance_id):

    """
    Our Lambda function operates in five-minute time samples, however
    we eventually give up our actions if they take more than 60 minutes.

    This function finds out how long we've been working on our present
    operation by listing current Autoscaling activities, and checking
    for our instance ID to get a datestamp.

    We can then compare that datestamp with present to determine our
    overall duration.
    """

    paginator = asg_c.get_paginator('describe_scaling_activities')

    response_iterator = paginator.paginate(
        AutoScalingGroupName=asg_name,
        PaginationConfig={
            'PageSize': 10,
        }
    )

    hook_start_time = datetime.datetime.utcnow()
    for response in response_iterator:
        for activity in response["Activities"]:
            if re.match(
                    "Terminating.*{}".format(instance_id),
                    activity["Description"]
                    ):
                hook_start_time = activity["StartTime"]
                continue

    hook_start_time = hook_start_time.replace(tzinfo=None)

    hook_duration = (datetime.datetime.utcnow() - hook_start_time).total_seconds()

    return(int(hook_duration))


def check_stable_cluster(ecs_c, cluster_name, context, ecr_c):

    """
    Goes through all services, and tasks defined against a cluster
    and decides whether they are considered in a stable state.

    For Services we look for a 'service [x] has reached a steady state'
    as the most recent message in the services event list.

    For Tasks we look at the difference between the desired and actual
    states.  If there is a difference the task is not stable.

    When the cluster is finally stable, we will respond true.  If we
    have less than 40 seconds remaining in our Lambda function execution
    time then we will return false so we can send a heartbeat and
    be re-invoked.
    """

    services_stable = False
    tasks_stable = False

    services_stable = True
    paginator = ecs_c.get_paginator('list_services')
    services = paginator.paginate(
        cluster=cluster_name,
        PaginationConfig={
            "PageSize": 10
        }
    )

    for service in services:
        # Check for no services defined.
        if len(service["serviceArns"]) < 1:
            services_stable = True
            continue

        response = ecs_c.describe_services(
            cluster=cluster_name,
            services=service["serviceArns"]
        )

        for service_status in response["services"]:
            service_ready = False
            if re.search(
                    "service .* has reached a steady state\.",
                    service_status["events"][0]["message"]
                    ):
                service_ready = True
                continue

            if service_ready is False:
                print("! Service {} does not appear to be stable".format(
                    service_status["serviceName"]
                ))
                services_stable = False

    tasks_stable = True
    paginator = ecs_c.get_paginator('list_tasks')
    tasks = paginator.paginate(
        cluster=cluster_name,
        PaginationConfig={
            "PageSize": 100
        }
    )

    for task in tasks:
        # Check for no tasks defined.
        if len(task["taskArns"]) < 1:
            tasks_stable = True
            continue

        response = ecs_c.describe_tasks(
            cluster=cluster_name,
            tasks=task["taskArns"]
        )

        for task_status in response["tasks"]:
            if task_status["lastStatus"] != task_status["desiredStatus"]:
                print("! Task {} [{}] has desired status {} with last status {}".format(
                        task_status["taskArn"],
                        task_status["group"],
                        task_status["desiredStatus"],
                        task_status["lastStatus"]
                    )
                )
                tasks_stable = False

    if services_stable and tasks_stable:
        return(True)
    else:
        return(False)


def drain_instance(ecs_c, cluster_name, instance_id):

    """
    Marks the ECS container ID that we're set to terminate to DRAIN.
    """

    response = ecs_c.describe_container_instances(
        cluster=cluster_name,
        containerInstances=[
            instance_id
        ]
    )

    if response["containerInstances"][0]["status"] == "ACTIVE":
        # Artifical sleep to give any launching instances a chance to start
        # This can be improved
        ecs_c.update_container_instances_state(
            cluster=cluster_name,
            containerInstances=[
                instance_id
            ],
            status="DRAINING"
        )


def check_instance_drained(ecs_c, cluster_name, instance_id, context):

    """
    Checks and waits until an ECS instance has drained all its running tasks.

    Returns True if the instance drains.

    Returns False if there is less than 40 seconds left in the Lambda
    functions execution and we need to re-invoke to wait longer.
    """

    response = ecs_c.describe_container_instances(
        cluster=cluster_name,
        containerInstances=[
            instance_id
        ]
    )

    print("- Instance has {} running tasks and {} pending tasks".format(
        response["containerInstances"][0]["runningTasksCount"],
        response["containerInstances"][0]["pendingTasksCount"]
    ))

    if response["containerInstances"][0]["runningTasksCount"] == 0 and \
            response["containerInstances"][0]["pendingTasksCount"] == 0:
        return(True)
    else:
        return(False)


def lambda_handler(event, context):
    """
    Lambda entry point
    """
    proceed_with_termination = True
    print("Recieved event {}".format(json.dumps(event)))

    check_hour = datetime.now().hour
    print("check_hour is {}".format(check_hour))
    if 5 <= check_hour <= 6:
        proceed_with_termination = False
    else:
        for record in event['Records']:
            # Our hook message can look different depending on how we're called.
            # The initial call from AutoScaling has one format, and the call when
            # we send a HeartBeat message has another.  We need to massage them into
            # a consistent format.  We'll follow the format used by AutoScaling
            # versus the HeartBeat message.
            hook_message = {}
            messageId = record['messageId']
            # Identify if this is the AutoScaling call
            if "autoscaling:TEST_NOTIFICATION" in record['body']:
                print("Recieved a test notification, returning empty response.")
                break
            if "LifecycleHookName" in record['body']:
                hook_message = json.loads(record['body'])
            # Otherwise this is a HeartBeat call
            else:
                hook_message = json.loads(record['body']["requestParameters"])
                # Heartbeat comes with instanceId instead of EC2InstanceId
                hook_message["EC2InstanceId"] = hook_message["instanceId"]
                # Our other three elements need to be capitlized
                hook_message["LifecycleHookName"] = hook_message["lifecycleHookName"]
                hook_message["AutoScalingGroupName"] = \
                    hook_message["autoScalingGroupName"]
                hook_message["LifecycleActionToken"] = \
                    hook_message["lifecycleActionToken"]

            print("Recieved Lifecycle Hook message {}".format(
                json.dumps(hook_message)
            ))

            try:
                ec2_c = boto3.client('ec2')
                ecs_c = boto3.client('ecs')
                asg_c = boto3.client('autoscaling')
                ecr_c = boto3.client('ecr')
                dyn_c = boto3.client('dynamodb')

                print("Determining our ECS Cluster name . . .")
                cluster_name = find_cluster_name(
                    ec2_c,
                    hook_message["EC2InstanceId"]
                )
                print(". . . found ECS Cluster name '{}'".format(
                    cluster_name
                ))

                print("Verify docker images exist and remediate where appropriate.")
                verify_images(ecr_c, ecs_c, dyn_c, cluster_name)

                print("Translating our EC2 Instance ID into an ECS Instance ID . . .")
                container_instance_id = find_container_instance_id(
                    ecs_c,
                    cluster_name,
                    hook_message["EC2InstanceId"]
                )
                print(". . . found ECS Instance ID '{}'".format(
                    container_instance_id
                ))

                proceed_with_termination = False

                response = ecs_c.describe_container_instances(
                    cluster=cluster_name,
                    containerInstances=[container_instance_id]
                )
                if response["containerInstances"][0]["status"] != "DRAINING":
                    notify_teams(f'[ECS Cluster: {cluster_name}] Instance {hook_message["EC2InstanceId"]} has been set to DRAINING.')

                    print("Setting ECS Instance to drain . . .".format(
                        container_instance_id
                    ))
                    drain_instance(
                        ecs_c,
                        cluster_name,
                        container_instance_id
                    )
                    print(". . . ECS Instance ID '{}' in DRAINING mode".format(
                        container_instance_id
                    ))
                else:
                    print("Instance is still draining..")

                print("Confirming ECS Instance has drained all tasks . . .")
                instance_drained = check_instance_drained(
                    ecs_c,
                    cluster_name,
                    container_instance_id,
                    context
                )

                if instance_drained is True:
                    print(". . . ECS Instance ID '{}' has drained all tasks".format(
                        container_instance_id
                    ))
                    print("Confirming Cluster Services and Tasks are Stable . . .")
                    cluster_stable = check_stable_cluster(
                        ecs_c,
                        cluster_name,
                        context,
                        ecr_c
                    )
                    def _proceed_with_termination():
                        asg_c.complete_lifecycle_action(
                            LifecycleHookName=hook_message["LifecycleHookName"],
                            AutoScalingGroupName=hook_message["AutoScalingGroupName"],
                            LifecycleActionToken=hook_message["LifecycleActionToken"],
                            LifecycleActionResult="CONTINUE",
                            InstanceId=hook_message["EC2InstanceId"])
                        notify_teams(f'[ECS Cluster: {cluster_name}] Instance {hook_message["EC2InstanceId"]} has been terminated.')
                        nonlocal proceed_with_termination
                        proceed_with_termination = True

                    if cluster_stable is True:
                        print(". . . Cluster '{}' appears to be stable".format(
                            cluster_name
                        ))
                        print("Proceeding with instance id '{}' Termination".format(
                            hook_message["EC2InstanceId"]
                        ))
                        _proceed_with_termination()

                    if _cluster_unstable_action == "CONTINUE" and cluster_stable is not True:
                        print(f'Cluster {cluster_name} is unstable, this most likely means some services are unhealthy..')
                        print(f'We have decided to proceed based on configuration preferences..')
                        _proceed_with_termination()

            except Exception as e:
                # Our exception path is to not allow the instance to terminate.
                # Exceptions are raised when the instance isn't part of an ECS Cluster
                # already.
                print("Exception: {}".format(e))
                try:
                    print("Sending a Heartbeat to continue waiting")
                    asg_c.record_lifecycle_action_heartbeat(
                        LifecycleHookName=hook_message["LifecycleHookName"],
                        AutoScalingGroupName=hook_message["AutoScalingGroupName"],
                        LifecycleActionToken=hook_message["LifecycleActionToken"],
                        InstanceId=hook_message["EC2InstanceId"]
                    )
                    tracking_id = f'{context.function_name}-{hook_message["EC2InstanceId"]}-exception'
                    if should_we_notify(dyn_c, unique_id=tracking_id):
                        tracking_update(dyn_c, unique_id=tracking_id)
                        notify_teams(f'[EXCEPTION] Lambda {context.function_name} has errored. This is impacting termination of {hook_message["EC2InstanceId"]} as part of an Auto Scaling Group action. INVESTIGATE IMMEDIATELY')
                    return json.dumps({
                        "batchItemFailures": [
                            {
                                "itemIdentifier": f"{messageId}"
                            }
                        ]
                    })
                except ClientError:
                    print("Unable to send heartbeat, deleting message from queue.")
                    continue

    if proceed_with_termination is False:
        print("Sending a Heartbeat to continue waiting")
        asg_c.record_lifecycle_action_heartbeat(
            LifecycleHookName=hook_message["LifecycleHookName"],
            AutoScalingGroupName=hook_message["AutoScalingGroupName"],
            LifecycleActionToken=hook_message["LifecycleActionToken"],
            InstanceId=hook_message["EC2InstanceId"]
        )

        return json.dumps({
            "batchItemFailures": [
                {
                    "itemIdentifier": f"{messageId}"
                }
            ]
        })