resource "aws_autoscaling_group" "asg" {
  name                 = var.asg_name != null ? var.asg_name : "ecs_${var.name}_asg"
  max_size             = var.asg_max_size
  min_size             = var.asg_min_size
  health_check_type    = "EC2"
  desired_capacity     = var.asg_desired_capacity
  capacity_rebalance   = var.asg_capacity_rebalance
  default_cooldown     = var.asg_default_cooldown
  termination_policies = var.termination_policies
  vpc_zone_identifier  = var.asg_vpc_zone_identifier

  launch_configuration = aws_launch_configuration.lc.name


  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  #'to be enabled tactically
  dynamic "instance_refresh" {
    for_each = var.instance_refresh ? { "dummy" : "map" } : {}
    content {
      strategy = "Rolling"
      triggers = []
      preferences {
        min_healthy_percentage = 100
        checkpoint_percentages = []
      }
    }
  }

  tag {
    key                 = "Cluster"
    value               = "ECS ${var.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = lower(var.name)
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  tag {
    key                 = "Managed"
    value               = "Terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Monitored"
    value               = var.datadog_enable_monitoring
    propagate_at_launch = true
  }

#  lifecycle {
#    ignore_changes = [desired_capacity]
#  }
}

resource "aws_autoscaling_lifecycle_hook" "terminate" {
  name                    = "terminate"
  default_result          = "ABANDON"
  heartbeat_timeout       = 7200
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  autoscaling_group_name  = aws_autoscaling_group.asg.name
  notification_target_arn = aws_sqs_queue.asg_queue_terminate.arn
  role_arn                = aws_iam_role.autoscaling_lifecycle.arn
}

resource "aws_autoscaling_lifecycle_hook" "launch" {
  name                    = "launch"
  default_result          = "ABANDON"
  heartbeat_timeout       = 7200
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
  autoscaling_group_name  = aws_autoscaling_group.asg.name
  notification_target_arn = aws_sqs_queue.asg_queue_launch.arn
  role_arn                = aws_iam_role.autoscaling_lifecycle.arn
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.name}-instances-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = var.asg_default_cooldown
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name}-instances-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = var.asg_default_cooldown
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

