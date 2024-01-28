# test lives in production aws vpc
#environment = "test"
ecs_clusters = {
  "Staging" = {
    asg_name                = "ECS a Staging"
    lc_name                 = "ECS_Staging",
    lc_instance_type        = "r5a.large",
    lc_key_name             = "devops-2020-01",
    lc_iam_instance_profile = "arn:aws:iam::095955279155:instance-profile/ecsInstance-Staging",
    asg_min_size            = 1,
    asg_desired_capacity    = 1,
    asg_max_size            = 3,
    lc_enable_monitoring    = true,
    create_auto_stop_table  = true,
    asg_capacity_rebalance  = true
  },
  "Staging-nonui" = {
    asg_name                = "ECS Staging-nonui"
    lc_name                 = "ECS_Staging-nonui",
    lc_instance_type        = "t3.large",
    lc_key_name             = "devops-infrastructure",
    lc_iam_instance_profile = "arn:aws:iam::095955279155:instance-profile/ecsInstance-Staging-nonui",
    asg_min_size            = 1,
    asg_desired_capacity    = 1,
    asg_max_size            = 2,
    lc_enable_monitoring    = true,
    create_auto_stop_table  = true,
    asg_capacity_rebalance  = true
  },
  "Staging-extra" = {
    asg_name                = "ECS Staging-extra"
    lc_name                 = "ECS_Staging-extra",
    lc_instance_type        = "t3.large",
    lc_key_name             = "devops-infrastructure",
    lc_iam_instance_profile = "arn:aws:iam::095955279155:instance-profile/ecsInstance-Staging-extra",
    asg_min_size            = 1,
    asg_desired_capacity    = 1,
    asg_max_size            = 2,
    lc_enable_monitoring    = true,
    create_auto_stop_table  = true,
    asg_capacity_rebalance  = true
  }
}

image_does_not_exist_action = "STOP_SERVICE"
cluster_unstable_action     = "CONTINUE"
instance_refresh            = true
report_cron_schedule        = "cron(0 8 ? * MON *)"
