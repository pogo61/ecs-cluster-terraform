resource "aws_lambda_function" "lambda_monitor" {
  s3_bucket         = aws_s3_bucket.lambdabucket.id
  s3_key            = aws_s3_object.lambda_monitor_s3_upload.id
  s3_object_version = aws_s3_object.lambda_monitor_s3_upload.version_id
  function_name     = "ecs_${var.name}_monitor"
  role              = aws_iam_role.lambdarole.arn
  handler           = "lambda_monitor.lambda_handler"
  timeout           = 600
  memory_size       = 1024

  runtime = "python3.7"

  environment {
    variables = {
      TEAMS_WEBHOOK_URL_PRIVATE = var.teams_webhook_url_private,
      TEAMS_WEBHOOK_URL_PUBLIC  = var.teams_webhook_url_testers,
      ECS_CLUSTER               = var.name,
      DYNAMODB_TRACKING_TABLE   = aws_dynamodb_table.ecs-tracking.name
    }
  }
}

resource "aws_lambda_function" "lambda_launch" {
  s3_bucket                      = aws_s3_bucket.lambdabucket.id
  s3_key                         = aws_s3_object.lambda_launch_s3_upload.id
  s3_object_version              = aws_s3_object.lambda_launch_s3_upload.version_id
  function_name                  = "ecs_${var.name}_launch"
  role                           = aws_iam_role.lambdarole.arn
  handler                        = "lambda_launch.lambda_handler"
  timeout                        = 180
  memory_size                    = 1024
  reserved_concurrent_executions = 1

  runtime = "python3.7"

  environment {
    variables = {
      TEAMS_WEBHOOK_URL_PRIVATE = var.teams_webhook_url_private,
      TEAMS_WEBHOOK_URL_PUBLIC  = var.teams_webhook_url_public,
      DYNAMODB_TRACKING_TABLE   = aws_dynamodb_table.ecs-tracking.name
    }
  }
}

resource "aws_lambda_function" "lambda_terminate" {
  s3_bucket                      = aws_s3_bucket.lambdabucket.id
  s3_key                         = aws_s3_object.lambda_terminate_s3_upload.id
  s3_object_version              = aws_s3_object.lambda_terminate_s3_upload.version_id
  function_name                  = "ecs_${var.name}_terminate"
  role                           = aws_iam_role.lambdarole.arn
  handler                        = "lambda_terminate.lambda_handler"
  timeout                        = 180
  memory_size                    = 1024
  reserved_concurrent_executions = 1

  runtime = "python3.7"

  environment {
    variables = {
      IMAGE_DOES_NOT_EXIST_ACTION   = var.image_does_not_exist_action,
      IMAGE_DIGEST_NOT_FOUND_ACTION = var.image_digest_not_found_action,
      CLUSTER_UNSTABLE_ACTION       = var.cluster_unstable_action,
      TEAMS_WEBHOOK_URL_PRIVATE     = var.teams_webhook_url_private,
      TEAMS_WEBHOOK_URL_PUBLIC      = var.teams_webhook_url_public,
      DYNAMODB_TRACKING_TABLE       = aws_dynamodb_table.ecs-tracking.name
    }
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromeventbridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_monitor.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_iam_role" "lambdarole" {
  name = "${var.name}LambdaRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_event_source_mapping" "launch" {
  batch_size              = 1
  event_source_arn        = aws_sqs_queue.asg_queue_launch.arn
  function_name           = aws_lambda_function.lambda_launch.arn
  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_event_source_mapping" "terminate" {
  batch_size              = 1
  event_source_arn        = aws_sqs_queue.asg_queue_terminate.arn
  function_name           = aws_lambda_function.lambda_terminate.arn
  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_permission" "allow_event_report" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_monitor.function_name
  principal     = "events.amazonaws.com"
}
