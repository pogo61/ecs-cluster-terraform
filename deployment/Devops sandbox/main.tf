provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::051643391380:role/Sandbox"
  }
}

terraform {
  backend "s3" {
    region         = "eu-west-1"
    bucket         = "checkit-terraform-sandbox"
    key            = "checkit-clusters/sandbox-temp.tfstate"
    encrypt        = true
    dynamodb_table = "checkit-terraform-sandbox-locks"
    role_arn       = "arn:aws:iam::051643391380:role/Sandbox"
  }
}

# should this be here?
module "security_group" {
  source         = "../modules/security_group"
  sg_name        = "Sandbox-temp"
  sg_description = "Allows local network"
  vpc_id         = nonsensitive(jsondecode(data.aws_ssm_parameter.vpc_id.value))
  rules          = local.sandbox-temp_rules
  tags           = {
    name = "ECS ${var.environment}"
  }
}

module "ecs_cluster" {
  source   = "../modules/ecs-cluster"
  for_each = var.ecs_clusters

  name                    = each.key
  asg_vpc_zone_identifier = nonsensitive(jsondecode(data.aws_ssm_parameter.APP_subnets.value))
  lc_security_groups      = [nonsensitive(jsondecode(data.aws_ssm_parameter.default_security_group.value))]
  lc_key_name             = each.value["lc_key_name"]
  lc_image_id             = data.aws_ssm_parameter.ecs_ami.value
  # image for demo below
  #lc_image_id                 = "ami-0d8d8f76584c4a1ca"
  teams_webhook_url_public    = var.teams_webhook_url_public
  teams_webhook_url_private   = var.teams_webhook_url_private
  teams_webhook_url_testers   = var.teams_webhook_url_testers
  image_does_not_exist_action = var.image_does_not_exist_action
  cluster_unstable_action     = var.cluster_unstable_action
  instance_refresh            = var.instance_refresh
  create_auto_stop_table      = true
  environment                 = var.environment
}
