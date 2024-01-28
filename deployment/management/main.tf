provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "checkit-terraform"
    key            = "checkit-clusters/management-terraform.tfstate"
    dynamodb_table = "checkit-terraform-locks"
    encrypt        = true
  }
}

module "security_group" {
  source         = "../modules/security_group"
  sg_name        = "ManagementCluster"
  sg_description = "Allows local network"
  vpc_id         = nonsensitive(jsondecode(data.aws_ssm_parameter.vpc_id.value))
  rules          = local.management_rules
}

module "ecs_cluster" {
  source   = "../modules/ecs-cluster"
  for_each = var.ecs_clusters

  name                      = each.key
  asg_vpc_zone_identifier   = nonsensitive(jsondecode(data.aws_ssm_parameter.APP_subnets.value))
  lc_security_groups        = concat(each.value.lc_security_groups, [module.security_group.security_group_id], [nonsensitive(jsondecode(data.aws_ssm_parameter.vpn_security_group.value))])
  asg_name                  = each.value["asg_name"]
  lc_iam_instance_profile   = each.value["lc_iam_instance_profile"]
  lc_key_name               = each.value["lc_key_name"]
  lc_instance_type          = each.value["lc_instance_type"]
  asg_min_size              = each.value["asg_min_size"]
  asg_max_size              = each.value["asg_max_size"]
  asg_desired_capacity      = each.value["asg_desired_capacity"]
  lc_image_id               = nonsensitive(data.aws_ssm_parameter.ecs_ami.value)
  instance_refresh          = var.instance_refresh
  teams_webhook_url_testers = var.teams_webhook_url_testers
  report_cron_schedule      = var.report_cron_schedule
  environment               = var.environment
}
