#environment = "production"

ecs_clusters = {
  "Production" = {
    asg_name                  = "ECS Production",
    lc_name                   = "ECS Production",
    lc_instance_type          = "r5a.large",
    lc_key_name               = "devops-2019-11",
    lc_security_groups        = ["sg-a8151ad2"],
    lc_iam_instance_profile   = "ecsInstance-Production",
    lc_enable_monitoring      = true,
    datadog_enable_monitoring = "Yes",
    asg_max_size              = 15,
    asg_min_size              = 3,
    asg_desired_capacity      = 5,
    asg_capacity_rebalance    = true
  },
  "Production-nonui" = {
    asg_name                  = "ECS Production-nonui",
    lc_name                   = "ECS Production-nonui",
    lc_instance_type          = "m5.large",
    lc_key_name               = "devops-infrastructure",
    lc_security_groups        = ["sg-0ebe7bc0e591826af"],
    lc_iam_instance_profile   = "ecsInstance-Production-nonui",
    lc_enable_monitoring      = true,
    datadog_enable_monitoring = "Yes",
    asg_max_size              = 3,
    asg_min_size              = 1,
    asg_desired_capacity      = 1,
    asg_capacity_rebalance    = true
  },
  "Production-extra" = {
    asg_name                  = "ECS Production-extra",
    lc_name                   = "ECS Production-extra",
    lc_instance_type          = "m5.large",
    lc_key_name               = "devops-infrastructure",
    lc_security_groups        = ["sg-01ceaa82a465aad1d"],
    lc_iam_instance_profile   = "ecsInstance-Production-extra",
    lc_enable_monitoring      = true,
    datadog_enable_monitoring = "Yes",
    asg_max_size              = 3,
    asg_min_size              = 1,
    asg_desired_capacity      = 1,
    asg_capacity_rebalance    = true
  },
  "Production-reports" = {
    asg_name                  = "ECS Production-reports",
    lc_name                   = "ECS Production-reports",
    lc_instance_type          = "c5.large",
    lc_key_name               = "devops-infrastructure",
    lc_security_groups        = ["sg-0bd2586f99c80c61c"],
    lc_iam_instance_profile   = "ecsInstance-Production-reports",
    lc_enable_monitoring      = true,
    datadog_enable_monitoring = "Yes",
    asg_max_size              = 3,
    asg_min_size              = 1,
    asg_desired_capacity      = 1,
    asg_capacity_rebalance    = true
  }
}
instance_refresh = true