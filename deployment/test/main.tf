provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "checkit-terraform"
    key            = "checkit-clusters/staging-terraform.tfstate"
    dynamodb_table = "checkit-terraform-locks"
    encrypt        = true
  }
}

module "security_group" {
  for_each = {
    Staging       = local.staging_rules,
    Staging-nonui = local.staging_nonui_rules,
    Staging-extra = local.staging_extra_rules
  }
  source         = "../modules/security_group"
  sg_name        = each.key
  sg_description = "Allows local network"
  vpc_id         = nonsensitive(jsondecode(data.aws_ssm_parameter.vpc_id.value))
  rules          = each.value
  tags           = {
    name = "ECS ${var.environment}"
  }
}

module "ecs_cluster" {
  source   = "../modules/ecs-cluster"
  for_each = var.ecs_clusters

  name = each.key
  lc_security_groups = concat([nonsensitive(data.aws_ssm_parameter.default_security_group.value)], [
    module.security_group[each.key].security_group_id
  ])
  asg_vpc_zone_identifier     = nonsensitive(jsondecode(data.aws_ssm_parameter.APP_subnets.value))
  asg_name                    = each.value["asg_name"]
  lc_iam_instance_profile     = each.value["lc_iam_instance_profile"]
  lc_key_name                 = each.value["lc_key_name"]
  lc_instance_type            = each.value["lc_instance_type"]
  lc_image_id                 = data.aws_ssm_parameter.ecs_ami.value
  lc_name                     = each.value["lc_name"]
  asg_min_size                = each.value["asg_min_size"]
  asg_max_size                = each.value["asg_max_size"]
  asg_desired_capacity        = each.value["asg_desired_capacity"]
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
