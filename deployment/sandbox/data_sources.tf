data "aws_ssm_parameter" "default_security_group" {
  name = "/core_infrastructure/${var.environment}/default_security_group"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/core_infrastructure/${var.environment}/vpc_id"
}

data "aws_ssm_parameter" "APP_subnets" {
  name = "/core_infrastructure/${var.environment}/APP_subnets"
}

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}