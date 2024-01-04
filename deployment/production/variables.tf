variable "aws_region" {
  type        = string
  description = "EC2 Region for the VPC"
  default     = "eu-west-1"
}

variable "environment" {
  type        = string
  description = "AWS environment"
}

variable "ecs_clusters" {
  type = any
}

variable "instance_refresh" {
  description = "If set to true any changes to the launch config or asg (by terraform) will trigger an instance refresh automatically."
  type        = bool
}