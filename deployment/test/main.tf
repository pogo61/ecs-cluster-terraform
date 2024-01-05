provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    region         = "eu-west-2"
    bucket         = "japara-terraform-state"
    key            = "platform/test-terraform.tfstate"
    dynamodb_table = "platform-terraform-locks"
    encrypt        = true
  }
}

module "security_group" {
  source         = "../modules/security_group"
  sg_name        = "Test"
  sg_description = "Allows local network"
  vpc_id         = nonsensitive(jsondecode(data.aws_ssm_parameter.vpc_id.value))
  rules          = local.test_rules
  tags           = {
    name = "ECS ${var.environment}"
  }
}

module "ecs_cluster" {
  source   = "../modules/ecs_1.2.0"
  for_each = var.ecs_clusters

  name                    = each.key
  lc_security_groups      = concat(each.value.lc_security_groups, [module.security_group.security_group_id])
  asg_vpc_zone_identifier = nonsensitive(jsondecode(data.aws_ssm_parameter.APP_subnets.value))
  #  asg_vpc_zone_identifier = [
  #    nonsensitive(element(jsondecode(data.aws_ssm_parameter.APP_subnets.value), 0)),
  #    nonsensitive(element(jsondecode(data.aws_ssm_parameter.APP_subnets.value), 2))
  #  ]
  asg_name                    = each.value["asg_name"]
  lc_iam_instance_profile     = each.value["lc_iam_instance_profile"]
  lc_key_name                 = each.value["lc_key_name"]
  lc_instance_type            = each.value["lc_instance_type"]
  lc_enable_monitoring        = each.value["lc_enable_monitoring"]
  datadog_enable_monitoring   = each.value["datadog_enable_monitoring"]
  lc_image_id                 = data.aws_ssm_parameter.ecs_ami.value
  lc_name                     = each.value["lc_name"]
  asg_desired_capacity        = each.value["asg_desired_capacity"]
  asg_min_size                = each.value["asg_min_size"]
  asg_max_size                = each.value["asg_max_size"]
  create_auto_stop_table      = each.value["create_auto_stop_table"]
  teams_webhook_url_public    = var.teams_webhook_url_public
  teams_webhook_url_private   = var.teams_webhook_url_private
  teams_webhook_url_testers   = var.teams_webhook_url_testers
  image_does_not_exist_action = var.image_does_not_exist_action
  cluster_unstable_action     = var.cluster_unstable_action
  instance_refresh            = var.instance_refresh
  report_cron_schedule        = var.report_cron_schedule
  environment                 = var.environment
}

resource "aws_ssm_parameter" "validated_image" {
  name  = "/core_infrastructure/latest_ecs_ami"
  type  = "String"
  value = data.aws_ssm_parameter.ecs_ami.value
}

