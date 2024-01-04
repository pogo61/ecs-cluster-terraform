variable "aws_region" {
  type        = string
  description = "EC2 Region for the VPC"
  default     = "eu-west-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "ecs_clusters" {}

variable "teams_webhook_url_testers" {
  description = "Microsoft Teams 365 webhook URL for TESTER messages (reports of services that are unhealthy and may be unable to restart)."
  type        = string
}

variable "instance_refresh" {
  description = "If set to true any changes to the launch config or asg (by terraform) will trigger an instance refresh automatically."
  type        = bool
}

variable "report_cron_schedule" {
  description = "CRON to apply to the report lambda. This will determine how often a report is generated and sent into Teams."
  type        = string
}