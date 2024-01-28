resource "aws_sqs_queue" "asg_queue_launch" {
  name                       = "${var.name}ASGLaunchQueue"
  visibility_timeout_seconds = 240
}

resource "aws_sqs_queue" "asg_queue_terminate" {
  name                       = "${var.name}ASGTerminateQueue"
  visibility_timeout_seconds = 240

}