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


# Function handles reporting into Teams on health of ECS clusters
#

import os
import boto3
import requests
from botocore.exceptions import ClientError
import json
import re

def notify_teams(message, public=False):
    """
    Function to send a message into Microsoft Teams using the requests library.

    Requires environment variables:
    - TEAMS_WEBHOOK_URL_PUBLIC
    - TEAMS_WEBOOK_URL_PRIVATE

    These environment variables must be set with a VALID webhook for 365
    """
    data = json.dumps({"text": message})
    _teams_webhook_url_public = os.getenv("TEAMS_WEBHOOK_URL_PUBLIC", "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/9368eb879d3d4a50925cb4f1c03b93ce/25a519c0-d1aa-419b-b691-07e22a206b4e")
    _teams_webhook_url_private = os.getenv("TEAMS_WEBHOOK_URL_PRIVATE", "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/9368eb879d3d4a50925cb4f1c03b93ce/25a519c0-d1aa-419b-b691-07e22a206b4e")
    if public and _teams_webhook_url_public is not None:
        requests.post(url=_teams_webhook_url_public, data=data)

    if _teams_webhook_url_private is not None and (_teams_webhook_url_private != _teams_webhook_url_public or not public):
        requests.post(url=_teams_webhook_url_private, data=data)

def verify_images(ecr_c, ecs_c, cluster_name):
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
                            try:
                                report = report + f'- *{service}* will be unable to restart. Image {image} could not be found.   \n'
                            except NameError:
                                report = f'- *{service}* will be unable to restart. Image {image} could not be found.   \n'
    try:
        return report
    except NameError:
        return None

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

def check_stable_cluster(ecs_c, cluster_name, loop=True):

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
    while services_stable is False:

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
                    try:
                        report = report + f'- *{service_status["serviceName"]}* is unstable   \n'
                    except NameError:
                        report = f'- *{service_status["serviceName"]}* is unstable   \n'
                    services_stable = False
        if not loop: break
    try:
        return report
    except NameError:
        return None

def lambda_handler(event, context):

    warnings = False
    print("Received event {}".format(json.dumps(event)))

    if event["detail-type"] == "CloudWatch Alarm State Change":
        notify_teams(f'CloudWatch Alarm {event["detail"]["alarmName"]} has changed state to {event["detail"]["state"]["value"]}.')

    else:

        ecs_c = boto3.client('ecs')
        ecr_c = boto3.client('ecr')
        cluster = os.getenv("ECS_CLUSTER", "Test")
        services_report = check_stable_cluster(ecs_c, cluster, loop=False)
        images_report = verify_images(ecr_c, ecs_c, cluster)

        header = f"## This is a report for the following ECS Cluster: {cluster}"

        if services_report is not None:
            images_report_critical = f'''
The following services will not restart due to missing images:
{images_report}
'''
        else:
            images_report_critical = ''

        if services_report is not None:
            services_report_critical = f'''
These services are reporting back as unstable indicating a potential problem, but not always:
{services_report}
'''
        else: services_report_critical = ''


        report = "   \n".join([header, images_report_critical, services_report_critical])

        if images_report_critical == '' and services_report_critical == '':
            print("Nothing to report.")
        else:
            notify_teams(report, public=True)
