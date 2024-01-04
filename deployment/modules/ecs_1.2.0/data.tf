data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

# using the file function  to read the file because of issue: https://github.com/hashicorp/terraform-provider-archive/issues/34
data "archive_file" "terminate" {
  type        = "zip"
  output_path = "${path.module}/files/lambda_terminate.zip"

  source {
    content  = file("${path.module}/files/lambda_terminate.py")
    filename = basename("${path.module}/files/lambda_terminate.py")
  }
}

# using the file function  to read the file because of issue: https://github.com/hashicorp/terraform-provider-archive/issues/34
data "archive_file" "launch" {
  type        = "zip"
  output_path = "${path.module}/files/lambda_launch.zip"

  source {
    content  = file("${path.module}/files/lambda_launch.py")
    filename = basename("${path.module}/files/lambda_launch.py")
  }
}

# using the file function  to read the file because of issue: https://github.com/hashicorp/terraform-provider-archive/issues/34
data "archive_file" "monitor" {
  type        = "zip"
  output_path = "${path.module}/files/lambda_monitor.zip"

  source {
    content  = file("${path.module}/files/lambda_monitor.py")
    filename = basename("${path.module}/files/lambda_monitor.py")
  }
}