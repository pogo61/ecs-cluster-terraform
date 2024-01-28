# resource "aws_ssm_parameter" "clusterName" {
#   name        = "/core_infrastructure/${var.environment}/ecs_${var.name}"
#   description = "${var.environment} VPC ID"
#   type        = "String"
#   value       = jsonencode(aws_vpc.general.id)

#   tags = {
#     environment = var.environment
#   }
# }

# Create parameter in parameter store containing the cloudwatch configuration
resource "aws_ssm_parameter" "cloudwatch_config" {
  description = "Cloudwatch agent config"
  name        = "AmazonCloudWatch-${var.name}"
  type        = "String"
  value       = templatefile("${path.module}/files/cloudwatch_config.json.tftpl", { "cloudwatch_log_group" = aws_cloudwatch_log_group.ec2_logs.name })
}