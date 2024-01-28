provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "checkit-terraform"
    key            = "checkit-clusters/production-terraform.tfstate"
    dynamodb_table = "checkit-terraform-locks"
    encrypt        = true
  }
}

 module "security_group" {
   for_each = {
     Production       = local.production_rules,
     Production-nonui = local.production_nonui_rules,
     Production-extra = local.production_extra_rules
     Production-reports = local.production_reports_rules
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

  name                      = each.key
  lc_security_groups        = concat([nonsensitive(data.aws_ssm_parameter.default_security_group.value)], each.value["lc_security_groups"])
  asg_vpc_zone_identifier   = nonsensitive(jsondecode(data.aws_ssm_parameter.APP_subnets.value))
  asg_name                  = each.value["asg_name"]
  lc_iam_instance_profile   = each.value["lc_iam_instance_profile"]
  lc_key_name               = each.value["lc_key_name"]
  lc_instance_type          = each.value["lc_instance_type"]
  lc_enable_monitoring      = each.value["lc_enable_monitoring"]
  datadog_enable_monitoring = each.value["datadog_enable_monitoring"]
  lc_image_id               = data.aws_ssm_parameter.ecs_ami.value
  lc_name                   = each.value["lc_name"]
  instance_refresh          = var.instance_refresh
  asg_min_size              = each.value["asg_min_size"]
  asg_max_size              = each.value["asg_max_size"]
  asg_desired_capacity      = each.value["asg_desired_capacity"]
  asg_capacity_rebalance    = each.value["asg_capacity_rebalance"]
  environment               = var.environment
}
