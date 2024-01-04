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

# Function handles management of new EC2 instances into ECS
#

import boto3
import os
import requests
import json
import base64
import re
from datetime import datetime

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

def find_cluster_name(ec2_c, instance_id):

    """
    Provided an instance that is currently, or should be part of an ECS cluster
    determines the ECS cluster name.  This is derived from the user-data
    which contains a command to inject the cluster name into ECS agent config
    files.

    On failure we raise an exception which means this instance isn't a ECS
    cluster member so we can proceed with termination.
    """

    response = ec2_c.describe_instance_attribute(
        InstanceId=instance_id,
        Attribute='userData'
    )

    userdata = base64.b64decode(response['UserData']['Value']).decode('unicode_escape')

    clustername = re.search("ECS_CLUSTER\s?=\s?(.*?)\s", str(userdata))
    if clustername:
        return(clustername.group(1).strip("'"))

    raise(ValueError(
        "Unable to determine the ECS cluster name from instance metadata"
    ))


def container_instance_healthy(ecs_c, cluster_name, instance_id, context):

    """
    Lists all the instances in the cluster to see if we have one joined
    that matches the instance ID of the one we've just started.

    If we find a cluster member that matches our recently launched instance
    ID, checks whether it's in a status of ACTIVE and shows it's ECS
    agent is connected to the cluster.

    There could be additional checks put in as desired to verify the
    instance is healthy!

    If we're getting short of time waiting for stability return false
    so we can get a continuation.
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
                if container_instance["status"] == "ACTIVE":
                    if container_instance["agentConnected"] is True:
                        return(True)
                    else:
                        return(False)
    return(False)


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

    hook_start_time = datetime.utcnow()
    for response in response_iterator:
        for activity in response["Activities"]:
            if re.match(
                    "Terminating.*{}".format(instance_id),
                    activity["Description"]
                    ):
                hook_start_time = activity["StartTime"]
                continue

    hook_start_time = hook_start_time.replace(tzinfo=None)

    hook_duration = (datetime.utcnow() - hook_start_time).total_seconds()

    return(int(hook_duration))


def lambda_handler(event, context):
    """
    Entry point for the Lambda execution
    """

    print("Received event {}".format(json.dumps(event)))

    for record in event['Records']:
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

        print("Received Lifecycle Hook message {}".format(
            json.dumps(hook_message)
        ))

        try:
            ec2_c = boto3.client('ec2')
            ecs_c = boto3.client('ecs')
            asg_c = boto3.client('autoscaling')

            print("Determining our ECS Cluster name . . .")
            cluster_name = find_cluster_name(
                ec2_c,
                hook_message["EC2InstanceId"]
            )
            print(". . . found ECS Cluster name '{}'".format(
                cluster_name
            ))

            print("Checking status of new instance in the ECS Cluster . . .")
            if container_instance_healthy(
                    ecs_c, cluster_name, hook_message["EC2InstanceId"], context
                    ):
                print(". . . Instance {} connected and active".format(
                    hook_message["EC2InstanceId"]
                ))
                print("Proceeding with instance {} Launch".format(
                    hook_message["EC2InstanceId"]
                ))
                asg_c.complete_lifecycle_action(
                    LifecycleHookName=hook_message["LifecycleHookName"],
                    AutoScalingGroupName=hook_message["AutoScalingGroupName"],
                    LifecycleActionToken=hook_message["LifecycleActionToken"],
                    LifecycleActionResult="CONTINUE",
                    InstanceId=hook_message["EC2InstanceId"]
                )
                notify_teams(f'[ECS Cluster: {cluster_name}] {hook_message["EC2InstanceId"]} has joined the cluster.')
            else:
                notify_teams(f'[ECS Cluster: {cluster_name}] {hook_message["EC2InstanceId"]} is launching..')
                print("Sending a Heartbeat to continue waiting")
                asg_c.record_lifecycle_action_heartbeat(
                    LifecycleHookName=hook_message["LifecycleHookName"],
                    AutoScalingGroupName=hook_message["AutoScalingGroupName"],
                    LifecycleActionToken=hook_message["LifecycleActionToken"],
                    InstanceId=hook_message["EC2InstanceId"])

                return json.dumps({
                    "batchItemFailures": [
                        {
                            "itemIdentifier": f"{messageId}"
                        }
                    ]
                })

        except Exception as e:
            print("Exception: {}".format(e))
            return json.dumps({
                "batchItemFailures": [
                    {
                        "itemIdentifier": f"{messageId}"
                    }
                ]
            })
            raise