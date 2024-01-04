# CheckIT ECS Module

## Summary
This module provisions an ECS cluster in a manor suitable for CheckIT use. Supported baked in for rolling upgrades on the underlying EC2 instances utilising Lambda functions to manage the process. See variable inputs for how this can be customised and required inputs.
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_lifecycle_hook.launch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_autoscaling_lifecycle_hook.terminate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_autoscaling_policy.scale_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_autoscaling_policy.scale_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_cloudwatch_event_rule.ecs_agent_running](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.trigger_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ecs_agent_running](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.ec2_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda_launch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda_monitor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda_terminate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.ecs_agent_running](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.scale_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.scale_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_dynamodb_table.ecs-tracking](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_ecs_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_iam_instance_profile.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.autoscaling_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lambdarole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_event_source_mapping.launch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_event_source_mapping.terminate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_function.lambda_launch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.lambda_monitor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.lambda_terminate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_event_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_launch_configuration.non_ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_s3_bucket.lambdabucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.lambdabucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_versioning.lambdabucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.lambda_launch_s3_upload](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.lambda_monitor_s3_upload](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.lambda_terminate_s3_upload](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_sqs_queue.asg_queue_launch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.asg_queue_terminate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_ssm_parameter.cloudwatch_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [archive_file.launch](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.monitor](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.terminate](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.autoscaling_lifecycle_ar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.autoscaling_lifecycle_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asg_capacity_rebalance"></a> [asg\_capacity\_rebalance](#input\_asg\_capacity\_rebalance) | Indicates whether capacity rebalance is enabled. | `bool` | `false` | no |
| <a name="input_asg_default_cooldown"></a> [asg\_default\_cooldown](#input\_asg\_default\_cooldown) | The amount of time, in seconds, after a scaling activity completes before another scaling activity can start. | `number` | `300` | no |
| <a name="input_asg_desired_capacity"></a> [asg\_desired\_capacity](#input\_asg\_desired\_capacity) | The number of Amazon EC2 instances that should be running in the group. | `number` | `2` | no |
| <a name="input_asg_max_instance_lifetime"></a> [asg\_max\_instance\_lifetime](#input\_asg\_max\_instance\_lifetime) | The maximum amount of time, in seconds, that an instance can be in service, values must be either equal to 0 or between 86400 and 31536000 seconds. | `number` | `0` | no |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | The maximum size of the Auto Scaling Group | `number` | `2` | no |
| <a name="input_asg_min_size"></a> [asg\_min\_size](#input\_asg\_min\_size) | The minimum size of the Auto Scaling Group | `number` | `2` | no |
| <a name="input_asg_name"></a> [asg\_name](#input\_asg\_name) | Name override for AutoScaling Group, if not set it will be generated automaticaly (recommended). | `string` | `null` | no |
| <a name="input_asg_vpc_zone_identifier"></a> [asg\_vpc\_zone\_identifier](#input\_asg\_vpc\_zone\_identifier) | List of subnets to launch ECS Container Instances within. | `list(string)` | n/a | yes |
| <a name="input_cluster_unstable_action"></a> [cluster\_unstable\_action](#input\_cluster\_unstable\_action) | Action to take if cluster is unstable, which means a service is unhealthy. Available actions are: CONTINUE, WAIT | `string` | `"WAIT"` | no |
| <a name="input_cpu_higher_bound"></a> [cpu\_higher\_bound](#input\_cpu\_higher\_bound) | Cluster CPU Utilization on which to trigger a scale UP actitvity (increase container instances). | `number` | `80` | no |
| <a name="input_cpu_lower_bound"></a> [cpu\_lower\_bound](#input\_cpu\_lower\_bound) | Cluster CPU Utilization on which to trigger a scale DOWN actitvity (reduce container instances). | `number` | `5` | no |
| <a name="input_image_digest_not_found_action"></a> [image\_digest\_not\_found\_action](#input\_image\_digest\_not\_found\_action) | Action to take if service relies on an image that has changed. Available actions are: CONTINUE | `string` | `"CONTINUE"` | no |
| <a name="input_image_does_not_exist_action"></a> [image\_does\_not\_exist\_action](#input\_image\_does\_not\_exist\_action) | Action to take if service relies on an image that does not exist. Available actions are: STOP\_SERVICE, WAIT | `string` | `"WAIT"` | no |
| <a name="input_instance_refresh"></a> [instance\_refresh](#input\_instance\_refresh) | If set to true any changes to the launch config or asg (by terraform) will trigger an instance refresh automatically. | `bool` | `false` | no |
| <a name="input_lc_ebs_optimized"></a> [lc\_ebs\_optimized](#input\_lc\_ebs\_optimized) | If true, the launched EC2 instance will be EBS-optimized. | `bool` | `true` | no |
| <a name="input_lc_enable_monitoring"></a> [lc\_enable\_monitoring](#input\_lc\_enable\_monitoring) | Enables/disables detailed monitoring. | `bool` | `false` | no |
| <a name="input_lc_iam_instance_profile"></a> [lc\_iam\_instance\_profile](#input\_lc\_iam\_instance\_profile) | The name attribute of the IAM instance profile to associate with launched instances. | `string` | `null` | no |
| <a name="input_lc_image_id"></a> [lc\_image\_id](#input\_lc\_image\_id) | AMI to use for the ECS Container Instances (EC2) | `string` | n/a | yes |
| <a name="input_lc_instance_type"></a> [lc\_instance\_type](#input\_lc\_instance\_type) | EC2 instance type to use for ECS Container Instances. | `string` | `"t3a.small"` | no |
| <a name="input_lc_key_name"></a> [lc\_key\_name](#input\_lc\_key\_name) | Key Pair Name as named on AWS to assign to instances. | `string` | `"devops-infrastructure"` | no |
| <a name="input_lc_name"></a> [lc\_name](#input\_lc\_name) | Name override for launch configuration, if not set it will be generated automaticaly (recommended). | `any` | `null` | no |
| <a name="input_lc_public_ip_address"></a> [lc\_public\_ip\_address](#input\_lc\_public\_ip\_address) | Whether or not to assign a public IP address to the EC2 instances. | `bool` | `true` | no |
| <a name="input_lc_security_groups"></a> [lc\_security\_groups](#input\_lc\_security\_groups) | Override default securtiy groups | `list(string)` | `null` | no |
| <a name="input_mem_reserve_higher_bound"></a> [mem\_reserve\_higher\_bound](#input\_mem\_reserve\_higher\_bound) | Cluster Memory Reservation on which to trigger a scale UP actitvity (increase container instances). | `number` | `75` | no |
| <a name="input_mem_reserve_lower_bound"></a> [mem\_reserve\_lower\_bound](#input\_mem\_reserve\_lower\_bound) | Cluster Memory Reservation on which to trigger a scale DOWN actitvity (reduce container instances). | `number` | `30` | no |
| <a name="input_mem_usage_higher_bound"></a> [mem\_usage\_higher\_bound](#input\_mem\_usage\_higher\_bound) | Cluster Memory Utilization on which to trigger a scale UP actitvity (increase container instances). | `number` | `80` | no |
| <a name="input_mem_usage_lower_bound"></a> [mem\_usage\_lower\_bound](#input\_mem\_usage\_lower\_bound) | Cluster Memory Utilization on which to trigger a scale DOWN actitvity (reduce container instances). | `number` | `30` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the ECS Cluster to create. | `string` | n/a | yes |
| <a name="input_report_cron_schedule"></a> [report\_cron\_schedule](#input\_report\_cron\_schedule) | CRON to apply to the report lambda. This will determine how often a report is generated and sent into Teams. | `string` | `"cron(0 9 ? * MON-FRI *)"` | no |
| <a name="input_teams_webhook_url_private"></a> [teams\_webhook\_url\_private](#input\_teams\_webhook\_url\_private) | Microsoft Teams 365 webhook URL for PRIVATE messages (verbose information about autoscaling activity). | `string` | `"https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/55dd5e78d4c043b599e17b1983b3a363/25a519c0-d1aa-419b-b691-07e22a206b4e"` | no |
| <a name="input_teams_webhook_url_public"></a> [teams\_webhook\_url\_public](#input\_teams\_webhook\_url\_public) | Microsoft Teams 365 webhook URL for PUBLIC messages (informative information such as services being stopped due to missing images). | `string` | `"https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/9368eb879d3d4a50925cb4f1c03b93ce/25a519c0-d1aa-419b-b691-07e22a206b4e"` | no |
| <a name="input_teams_webhook_url_testers"></a> [teams\_webhook\_url\_testers](#input\_teams\_webhook\_url\_testers) | Microsoft Teams 365 webhook URL for TESTER messages (reports of services that are unhealthy and may be unable to restart). | `string` | `"https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/55dd5e78d4c043b599e17b1983b3a363/25a519c0-d1aa-419b-b691-07e22a206b4e"` | no |
| <a name="input_termination_policies"></a> [termination\_policies](#input\_termination\_policies) | List of termination policies for the AutoScaling Group. Determines how instances are selected for termination, e.g. when desired count is reduced. | `list(string)` | <pre>[<br>  "OldestInstance"<br>]</pre> | no |
| <a name="input_wait_for_capacity_timeout"></a> [wait\_for\_capacity\_timeout](#input\_wait\_for\_capacity\_timeout) | A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. | `string` | `"10m"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->