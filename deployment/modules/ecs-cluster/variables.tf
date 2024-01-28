variable "instance_refresh" {
  description = "If set to true any changes to the launch config or asg (by terraform) will trigger an instance refresh automatically."
  type        = bool
  default     = false
}
variable "name" {
  description = "Name of the ECS Cluster to create."
  type        = string
}

variable "termination_policies" {
  description = "List of termination policies for the AutoScaling Group. Determines how instances are selected for termination, e.g. when desired count is reduced."
  type        = list(string)
  default     = ["OldestInstance"]
}

variable "lc_public_ip_address" {
  description = "Whether or not to assign a public IP address to the EC2 instances."
  type        = bool
  default     = true
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out."
  type        = string
  default     = "10m"
}

variable "lc_image_id" {
  description = "AMI to use for the ECS Container Instances (EC2)"
  type        = string
}

variable "lc_key_name" {
  description = "Key Pair Name as named on AWS to assign to instances."
  default     = "devops-infrastructure"
  type        = string
}

variable "lc_enable_monitoring" {
  description = "Enables/disables detailed monitoring. "
  default     = false
  type        = bool
}

variable "datadog_enable_monitoring" {
  description = "Enables/disables datadog monitoring. "
  default     = "No"
  type        = string
}


variable "lc_ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized."
  default     = true
  type        = bool
}

variable "asg_capacity_rebalance" {
  description = "Indicates whether capacity rebalance is enabled."
  default     = false
  type        = bool
}

variable "asg_default_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes before another scaling activity can start."
  default     = 300
  type        = number
}

variable "asg_max_instance_lifetime" {
  description = "The maximum amount of time, in seconds, that an instance can be in service, values must be either equal to 0 or between 86400 and 31536000 seconds."
  default     = 0
  type        = number
}

variable "lc_name" {
  description = "Name override for launch configuration, if not set it will be generated automaticaly (recommended)."
  default     = null
}

variable "lc_instance_type" {
  description = "EC2 instance type to use for ECS Container Instances."
  default     = "t3a.small"
  type        = string
}

variable "lc_security_groups" {
  description = "Override default securtiy groups"
  default     = null
  type        = list(string)
}

variable "asg_name" {
  description = "Name override for AutoScaling Group, if not set it will be generated automaticaly (recommended)."
  default     = null
  type        = string
}

variable "asg_max_size" {
  description = "The maximum size of the Auto Scaling Group"
  default     = 2
  type        = number
}

variable "asg_min_size" {
  description = "The minimum size of the Auto Scaling Group"
  default     = 2
  type        = number
}

variable "asg_desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group."
  default     = 2
  type        = number
}

variable "asg_vpc_zone_identifier" {
  description = "List of subnets to launch ECS Container Instances within."
  type        = list(string)
}

variable "lc_iam_instance_profile" {
  description = "The name attribute of the IAM instance profile to associate with launched instances."
  default     = null
  type        = string
}

variable "cpu_lower_bound" {
  description = "Cluster CPU Utilization on which to trigger a scale DOWN actitvity (reduce container instances)."
  default     = 25
  type        = number
}

variable "mem_usage_lower_bound" {
  description = "Cluster Memory Utilization on which to trigger a scale DOWN actitvity (reduce container instances)."
  default     = 35
  type        = number
}

variable "mem_reserve_lower_bound" {
  description = "Cluster Memory Reservation on which to trigger a scale DOWN actitvity (reduce container instances)."
  default     = 35
  type        = number
}

variable "cpu_higher_bound" {
  description = "Cluster CPU Utilization on which to trigger a scale UP actitvity (increase container instances)."
  default     = 85
  type        = number
}

variable "mem_usage_higher_bound" {
  description = "Cluster Memory Utilization on which to trigger a scale UP actitvity (increase container instances)."
  default     = 85
}

variable "mem_reserve_higher_bound" {
  description = "Cluster Memory Reservation on which to trigger a scale UP actitvity (increase container instances)."
  default     = 85
  type        = number
}

variable "image_does_not_exist_action" {
  description = "Action to take if service relies on an image that does not exist. Available actions are: STOP_SERVICE, WAIT"
  default     = "WAIT"
  type        = string
}

variable "image_digest_not_found_action" {
  description = "Action to take if service relies on an image that has changed. Available actions are: CONTINUE"
  default     = "CONTINUE"
  type        = string
}

variable "cluster_unstable_action" {
  description = "Action to take if cluster is unstable, which means a service is unhealthy. Available actions are: CONTINUE, WAIT"
  default     = "WAIT"
  type        = string
}

variable "teams_webhook_url_public" {
  description = "Microsoft Teams 365 webhook URL for PUBLIC messages (informative information such as services being stopped due to missing images)."
  default     = "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/9368eb879d3d4a50925cb4f1c03b93ce/25a519c0-d1aa-419b-b691-07e22a206b4e"
  type        = string
}

variable "teams_webhook_url_private" {
  description = "Microsoft Teams 365 webhook URL for PRIVATE messages (verbose information about autoscaling activity)."
  default     = "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/55dd5e78d4c043b599e17b1983b3a363/25a519c0-d1aa-419b-b691-07e22a206b4e"
  type        = string
}

variable "teams_webhook_url_testers" {
  description = "Microsoft Teams 365 webhook URL for TESTER messages (reports of services that are unhealthy and may be unable to restart)."
  default     = "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/55dd5e78d4c043b599e17b1983b3a363/25a519c0-d1aa-419b-b691-07e22a206b4e"
  type        = string
}

variable "report_cron_schedule" {
  description = "CRON to apply to the report lambda. This will determine how often a report is generated and sent into Teams."
  default     = "cron(0 9 ? * MON-FRI *)"
  type        = string
}

variable "create_auto_stop_table" {
  description = "If true the module will create a dynamodb table to support the auto-stop-start scripts."
  default     = false
  type        = bool
}

variable "environment" {
  type        = string
  description = "AWS environment"
}