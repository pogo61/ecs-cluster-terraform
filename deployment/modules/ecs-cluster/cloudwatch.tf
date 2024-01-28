resource "aws_cloudwatch_log_group" "ec2_logs" {
  name = "${var.name}-container-instance-logs"

  retention_in_days = 30
}

resource "aws_cloudwatch_metric_alarm" "ecs_agent_running" {
  alarm_name                = "${var.name}-isECSAgentRunning"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "3"
  metric_name               = "ecs_agent_running"
  namespace                 = "CWAgent"
  period                    = "60"
  statistic                 = "Minimum"
  threshold                 = "1"
  alarm_description         = "This metric reports ECS Agent Status, 1 for OK, 0 for not."
  insufficient_data_actions = []
  dimensions = {
    AutoScalingGroupName = var.asg_name != null ? var.asg_name : "ecs_${var.name}_asg"
  }
}

resource "aws_cloudwatch_event_rule" "ecs_agent_running" {
  name        = "${var.name}-isECSAgentRunning"
  description = "capture alarms on ecs_agent_running metric"

  event_pattern = <<EOF
  {
    "source": [
      "aws.cloudwatch"
    ],
    "detail-type": [
      "CloudWatch Alarm State Change"
    ],
    "resources": [
      "${aws_cloudwatch_metric_alarm.ecs_agent_running.arn}"
    ],
    "detail": {
      "state": {
        "value": [
          "ALARM", "OK"
        ]
      }
    }
  }
  EOF
}

resource "aws_cloudwatch_event_target" "ecs_agent_running" {
  rule      = aws_cloudwatch_event_rule.ecs_agent_running.name
  target_id = "TriggerLambdaAlarm"
  arn       = aws_lambda_function.lambda_monitor.arn
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_description = "This alarm monitors ${var.name}"
  alarm_name        = "${var.name}-instances-scaling-up"

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]

  evaluation_periods  = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"
  metric_query {
    id          = "e1"
    expression  = "IF(cpu >= ${var.cpu_higher_bound}, 1, 0) OR IF(memory >= ${var.mem_usage_higher_bound}, 1, 0) OR IF(memres >= ${var.mem_reserve_higher_bound}, 1, 0)"
    label       = "ScalingAlarm"
    return_data = "true"
  }

  metric_query {
    id          = "cpu"
    return_data = "false"
    metric {
      namespace   = "AWS/ECS"
      metric_name = "CPUUtilization"
      period      = 300
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.cluster.name
      }
    }
  }

  metric_query {
    id          = "memory"
    return_data = "false"
    metric {
      namespace   = "AWS/ECS"
      metric_name = "MemoryUtilization"
      period      = 300
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.cluster.name
      }
    }
  }

  metric_query {
    id          = "memres"
    return_data = "false"
    metric {
      namespace   = "AWS/ECS"
      metric_name = "MemoryReservation"
      period      = 300
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.cluster.name
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_description = "This alarm monitors ${var.name}"
  alarm_name        = "${var.name}-instances-scaling-down"

  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  evaluation_periods  = var.name == "Test" ? "5" : "3"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"

  metric_query {
    id          = "e1"
    expression  = "IF(cpu <= ${var.cpu_lower_bound}, 1, 0) AND IF(memory <= ${var.mem_usage_lower_bound}, 1, 0) AND IF(memres <= ${var.mem_reserve_lower_bound}, 1, 0)"
    label       = "ScalingAlarm"
    return_data = "true"
  }

  metric_query {
    id          = "cpu"
    return_data = "false"
    metric {
      namespace   = "AWS/ECS"
      metric_name = "CPUUtilization"
      period      = 300
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.cluster.name
      }
    }
  }

  metric_query {
    id          = "memory"
    return_data = "false"
    metric {
      namespace   = "AWS/ECS"
      metric_name = "MemoryUtilization"
      period      = 300
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.cluster.name
      }
    }
  }
  metric_query {

    id          = "memres"
    return_data = "false"
    metric {
      namespace   = "AWS/ECS"
      metric_name = "MemoryReservation"
      period      = 300
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.cluster.name
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "trigger_report" {
  name                = "${var.name}-Cluster-Report"
  description         = "Report on Cluster health nightly"
  schedule_expression = var.report_cron_schedule
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.trigger_report.name
  target_id = aws_lambda_function.lambda_monitor.function_name
  arn       = aws_lambda_function.lambda_monitor.arn
}

resource "aws_cloudwatch_log_group" "lambda_monitor" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_monitor.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_terminate" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_terminate.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_launch" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_launch.function_name}"
  retention_in_days = 14
}