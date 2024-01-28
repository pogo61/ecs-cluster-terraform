variable "aws_region" {
  type        = string
  description = "EC2 Region for the VPC"
  default     = "eu-west-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "Sandbox-temp"
}
variable "ecs_clusters" {
  type = any
}

variable "image_does_not_exist_action" {
  description = "Action to take if service relies on an image that does not exist. Available actions are: STOP_SERVICE, WAIT"
  type        = string
}

variable "cluster_unstable_action" {
  description = "Action to take if cluster is unstable, which means a service is unhealthy. Available actions are: CONTINUE, WAIT"
  type        = string
}

variable "teams_webhook_url_public" {
  description = "Microsoft Teams 365 webhook URL for PUBLIC messages (informative information such as services being stopped due to missing images)."
  type        = string
}

variable "teams_webhook_url_private" {
  description = "Microsoft Teams 365 webhook URL for PRIVATE messages (verbose information about autoscaling activity)."
  type        = string
}

variable "teams_webhook_url_testers" {
  description = "Microsoft Teams 365 webhook URL for TESTER messages (reports of services that are unhealthy and may be unable to restart)."
  type        = string
}

variable "instance_refresh" {
  description = "If set to true any changes to the launch config or asg (by terraform) will trigger an instance refresh automatically."
  type        = bool
}
