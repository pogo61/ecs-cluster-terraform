resource "aws_iam_instance_profile" "default" {
  count = var.lc_iam_instance_profile != null ? 0 : 1
  name  = "ecsinstance_${var.name}_default"
  role  = aws_iam_role.default[0].name
}

resource "aws_iam_role" "default" {
  count = var.lc_iam_instance_profile != null ? 0 : 1
  name  = "ecsinstance_${var.name}_default"
  path  = "/"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "autoscaling_lifecycle_ar" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "autoscaling_lifecycle_policy" {
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl"
    ]
    resources = [
      aws_sqs_queue.asg_queue_launch.arn,
      aws_sqs_queue.asg_queue_terminate.arn
    ]
  }
}

resource "aws_iam_role" "autoscaling_lifecycle" {
  name = "ecsinstance_${var.name}_autoscaling_lifecycle"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.autoscaling_lifecycle_ar.json
  inline_policy {
    name   = "my_inline_policy"
    policy = data.aws_iam_policy_document.autoscaling_lifecycle_policy.json
  }
}

resource "aws_ssm_parameter" "cluster_iam_role" {
  name  = "/${var.environment}/${var.name}/cluster_iam_role"
  type  = "String"
  value = aws_iam_role.autoscaling_lifecycle.arn
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.name}LambdaPolicy"
  path        = "/"
  description = "IAM policy for ${var.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstanceAttribute",
        "ecs:ListServices",
        "ecr:DescribeImages",
        "ecs:ListContainerInstances",
        "ecs:DescribeContainerInstances",
        "ecs:ListTasks",
        "ecs:DescribeServices",
        "ecs:DescribeTasks",
        "ecs:DescribeTaskDefinition"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:*"
      ],
      "Resource": [
        "${aws_dynamodb_table.ecs-tracking.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": [
        "${aws_sqs_queue.asg_queue_launch.arn}",
        "${aws_sqs_queue.asg_queue_terminate.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateContainerInstancesState"
      ],
      "Resource": "arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:container-instance/${aws_ecs_cluster.cluster.name}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService"
      ],
      "Resource": "arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.cluster.name}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:CompleteLifecycleAction",
        "autoscaling:RecordLifecycleActionHeartbeat"
      ],
      "Resource": "${aws_autoscaling_group.asg.arn}"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambdarole.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
