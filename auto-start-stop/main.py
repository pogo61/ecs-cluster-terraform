#!/bin/python

import boto3
import argparse
import time
from boto3.dynamodb.conditions import Key, Attr


def find_asgs(clusterName):
    """
    Provided an instance that is currently, or should be part of an ECS cluster
    determines the ECS cluster name.  This is derived from the user-data
    which contains a command to inject the cluster name into ECS agent config
    files.

    On failure we raise an exception which means this instance isn't a ECS
    cluster member so we can proceed with termination.
    """
    asg_list = list()
    if action == "stop":
        container_instances = _ecs_c.list_container_instances(
            cluster=clusterName,
        )
        if len(container_instances['containerInstanceArns']) > 0:
            response = _ecs_c.describe_container_instances(
                cluster=clusterName,
                containerInstances=container_instances['containerInstanceArns']
            )

            ec2_instances = list()
            for instance in response['containerInstances']:
                ec2_instances.append(instance['ec2InstanceId'])

            response = _autoscaling_c.describe_auto_scaling_instances(
                InstanceIds=ec2_instances,
                MaxRecords=50
            )

            for asg in response['AutoScalingInstances']:
                asg_name = asg['AutoScalingGroupName']
                if asg_name not in asg_list:
                    asg_list.append(asg_name)
        else:
            print("No instances found in cluster.")
    elif action == "start":
        table_r = _dyn_r.Table(table)
        response = table_r.query(
            IndexName="Cluster-index",
            KeyConditions={
                'Cluster': {
                    'AttributeValueList': [
                        clusterName,
                    ],
                    'ComparisonOperator': 'EQ'
                }
            },
            FilterExpression=Attr('Type').eq('asg'),
        )
        for asg in response['Items']:
            if asg['Service'] not in asg_list:
                asg_list.append(asg['Service'])

    return asg_list


def update_asg(asgs, action):
    """
  Update ASG
  """

    for asg_name in asgs:
        response = _autoscaling_c.describe_auto_scaling_groups(
            AutoScalingGroupNames=[
                asg_name,
            ],
        )['AutoScalingGroups'][0]
        if action == "stop":
            desired_capacity = 0
            min_size = 0

            # Ignore ASGs that are not running
            if response['DesiredCapacity'] == 0: continue
            item = {
                'Service': asg_name,
                'DesiredCapacity': response['DesiredCapacity'],
                'MinSize': response['MinSize'],
                'Type': 'asg',
                'Cluster': cluster_name
            }
            record_service_state(table, item)
        elif action == "start":
            last_state = get_last_service_state(table, asg_name)
            if last_state is None: last_state['DesiredCapacity'] = 1

            desired_capacity = int(last_state['DesiredCapacity'])
            min_size = int(last_state['MinSize'])
            if response['MinSize'] >= min_size or response['DesiredCapacity'] >= desired_capacity:
                print(f"ASG {asg_name} already at an appropriate size. No update required.")
                continue

        print(f"Updating ASG ({asg_name}) to {desired_capacity} EC2 instances.")
        _autoscaling_c.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            MinSize=min_size,
            DesiredCapacity=desired_capacity
        )


def stop_service(ecs_cluster_name, service):
    print(f"Stopping {service}.")
    _ecs_c.update_service(
        cluster=ecs_cluster_name,
        service=service,
        desiredCount=0)


def start_service(ecs_cluster_name, service):
    print(f"Starting {service}.")

    _ecs_c.update_service(
        cluster=ecs_cluster_name,
        service=service,
        desiredCount=int(get_last_service_state(table, service_name=service)['DesiredCount']))


def check_keycloak_stop(services, ecs_cluster_name):

    if len(services) < 16:
        _ecs_c.update_service(
            cluster=ecs_cluster_name,
            service="testing-checkit-auth",
            desiredCount=0)


def check_keycloak_start(services, ecs_cluster_name):
    _ecs_c.update_service(
        cluster=ecs_cluster_name,
        service="testing-checkit-auth",
        desiredCount=1)


def update_service(ecs_cluster_name, service_name, action):
    """
    Stop or Start a specific service or envionrment on an ECS Cluster
    """
    if action not in ("stop", "start"): raise ValueError(
        "Action passed to update_all_services is not valid. Must be stop or start.")

    services_result = _ecs_c.list_services(
        cluster=ecs_cluster_name,
        maxResults=100,
        launchType='EC2',
        schedulingStrategy='REPLICA'
    )

    services = services_result['serviceArns']

    while True:
        # if action == "stop":
        #     # check to see if Keycloak needs stopping
        #     check_keycloak_stop(services, ecs_cluster_name)
        # elif action == "start":
        #     # ensure keycloak is started
        #     check_keycloak_start(services, ecs_cluster_name)

        for service in services:
            if service_name in service:
                response = _ecs_c.describe_services(
                    cluster=cluster_name,
                    services=[
                        service
                    ])['services'][0]

                if action == "stop":
                    # Ignore services that are not running
                    if response['desiredCount'] == 0:
                        print(f"Service is {service} already stopped")
                        continue

                    item = {
                        'Service': response['serviceName'],
                        'Cluster': cluster_name,
                        'DesiredCount': response['desiredCount'],
                        'Type': 'service'
                    }
                    record_service_state(table, item)
                    desired_count = 0
                elif action == "start":
                    result = get_last_service_state(table, service_name=response['serviceName'])
                    if result is None:
                        desired_count = 1
                    else:
                        desired_count = int(result['DesiredCount'])
                    if desired_count == 0:
                        desired_count = 1

                _ecs_c.update_service(
                    cluster=ecs_cluster_name,
                    service=service,
                    desiredCount=desired_count)

                print(f"{service} has been updated.")
        try:
            more_services = _ecs_c.list_services(
                cluster=ecs_cluster_name,
                maxResults=100,
                nextToken=services_result['nextToken'],
                launchType='EC2',
                schedulingStrategy='REPLICA'
            )
            services_result = more_services
        except KeyError:
            print("no more services")
            exit(0)


def update_all_services(ecs_cluster_name, action):
    """
  Stop or Start ALL Services on an ECS Cluster
  """
    
    if action not in ("stop", "start"): raise ValueError(
        "Action passed to update_all_services is not valid. Must be stop or start.")

    if action == "start":
        start_rds_cluster(ecs_cluster_name)

    paginator = _ecs_c.get_paginator('list_services')
    services = paginator.paginate(
        cluster=ecs_cluster_name,
        PaginationConfig={
            "PageSize": 100
        }
    )
    
    print(f"Performing a {action} on ALL services that were/are running.")
    for page in services:
        for service in page['serviceArns']:
            response = _ecs_c.describe_services(
                cluster=cluster_name,
                services=[
                    service
                ])['services'][0]

            if action == "stop":
                # Ignore services that are not running
                if response['desiredCount'] == 0: continue

                # Ignore services deamon-based
                if response['schedulingStrategy'] == 'DAEMON': continue

                item = {
                    'Service': response['serviceName'],
                    'Cluster': cluster_name,
                    'DesiredCount': response['desiredCount'],
                    'Type': 'service'
                }
                record_service_state(table, item)
                desired_count = 0
            elif action == "start":
                # Ignore services deamon-based
                if response['schedulingStrategy'] == 'DAEMON': continue
                result = get_last_service_state(table, service_name=response['serviceName'])
                if result is None: continue
                desired_count = int(result['DesiredCount'])

            try:
                _ecs_c.update_service(
                    cluster=ecs_cluster_name,
                    service=service,
                    desiredCount=desired_count)
            except Exception as e:
                print(f"got and error {e} on the service {service}.")

    if action == "stop":
        stop_rds_cluster(ecs_cluster_name)


def stop_rds_cluster(ecs_cluster_name):
    """
  Stop the RDS cluster with the DB's for the services an ECS Cluster
  """

    # at the moment only the Staging RDS cluster is stopped. Not used if ECS cluster is Staging-extra or Staging-nonui
    if "staging" == ecs_cluster_name.lower():
        paginator = _rds_c.get_paginator('describe_db_clusters').paginate()
        for page in paginator:
            for dbcluster in page['DBClusters']:
                print("cluster found is: ", dbcluster['DBClusterIdentifier'].lower())
                if "staging" in dbcluster['DBClusterIdentifier'].lower():
                    try:
                        response = _rds_c.stop_db_cluster(
                            DBClusterIdentifier=dbcluster['DBClusterIdentifier']
                        )
                        print("cluster {} is stopped".format(dbcluster['DBClusterIdentifier'].lower()))
                    except Exception as e:
                        print("stop failed. response is {}".format(response))
                        return e
                else:
                    print("cluster id is: {} ".format(dbcluster['DBClusterIdentifier'].lower()))


def start_rds_cluster(ecs_cluster_name):
    """
  Start the RDS cluster with the DB's for the services an ECS Cluster
  """

    # at the moment only the Staging RDS cluster is stopped. Not used if ECS cluster is Staging-extra or Staging-nonui
    if "staging" == ecs_cluster_name.lower():
        paginator = _rds_c.get_paginator('describe_db_clusters').paginate()
        for page in paginator:
            for dbcluster in page['DBClusters']:
                print("cluster found is: ", dbcluster['DBClusterIdentifier'].lower())
                if "staging" in dbcluster['DBClusterIdentifier'].lower():
                    try:
                        response = _rds_c.start_db_cluster(
                            DBClusterIdentifier=dbcluster['DBClusterIdentifier']
                        )
                        print("cluster {} is started".format(dbcluster['DBClusterIdentifier'].lower()))
                    except Exception as e:
                        print("start failed. response is {}".format(response))
                        return e
                else:
                    print("cluster id is: {} ".format(dbcluster['DBClusterIdentifier'].lower()))


def get_last_service_state(table_name, service_name):
    """

  """
    db_table = _dyn_r.Table(table_name)
    response = db_table.query(
        KeyConditionExpression=Key('Service').eq(service_name) & Key('Cluster').eq(cluster_name)
    )
    print(f"The Service is {service_name}")
    if len(response['Items']) == 0:
        return None

    try:
        return response['Items'][0]
    except KeyError:
        return None
    except IndexError:
        return 0

def record_service_state(table_name, item):
    """

  """

    db_table = _dyn_r.Table(table_name)
    db_table.put_item(
        Item=item
    )


def is_service_ok(service_name):
    response = _ecs_c.describe_services(
        cluster=cluster_name,
        services=[
            service_name
        ])['services'][0]

    if response['runningCount'] == response['desiredCount']:
        tasks_running = True
    else:
        tasks_running = False

    if "steady state" in response['events'][0]['message']:
        tasks_steady = True
    else:
        tasks_steady = False

    if tasks_running and tasks_steady:
        return True
    else:
        print(f'Last event: {response["events"][0]["message"]}')
        return False


_parser = argparse.ArgumentParser()
_parser.add_argument('--action', help='Action to perform, options are: stop, start')
_parser.add_argument('--service', help='Service to start or stop', default=None)
_parser.add_argument('--cluster', help='Cluster to start or stop')
args = _parser.parse_args()

if __name__ == "__main__":

    action = args.action
    cluster_name = args.cluster
    service_name = args.service

    table = f"ecs_{cluster_name}_auto_stop"

    _dyn_r = boto3.resource('dynamodb', region_name='eu-west-1')
    _ecs_c = boto3.client('ecs', region_name='eu-west-1')
    _autoscaling_c = boto3.client('autoscaling', region_name='eu-west-1')
    _rds_c = boto3.client('rds', region_name='eu-west-1')

    asgs = find_asgs(cluster_name)
    print(f"Performing a {action} on ASGs {asgs}.")

    if service_name is None:
        update_asg(asgs, action)
        update_all_services(cluster_name, action)
    else:
        if action == "start": update_asg(asgs, action)
        update_service(cluster_name, service_name, action)
