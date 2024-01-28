locals {
  date = formatdate("YYYYMMDD", timestamp())
  module_tags = {
    Terraform_Module = "ecs_1.2.0"
  }
}