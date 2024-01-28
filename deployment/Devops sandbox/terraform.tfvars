ecs_clusters = {
  "Sandbox" = {
    asg_name                  = "ECS Sandbox",
    lc_name                   = "ECS Sandbox",
    lc_instance_type          = "t3.small",
    lc_key_name               = "devops-sandbox",
    lc_security_groups        = ["sg-0b83384b43e1e6101"],
    lc_iam_instance_profile   = "ecsInstance-Sandbox",
    lc_enable_monitoring      = true,
    datadog_enable_monitoring = "Yes",
    asg_max_size              = 1,
    asg_min_size              = 1,
    asg_desired_capacity      = 1,
    asg_capacity_rebalance    = true
  }
}

image_does_not_exist_action = "STOP_SERVICE"
#image_does_not_exist_action = "WAIT"
cluster_unstable_action = "CONTINUE"
#cluster_unstable_action     = "WAIT"
instance_refresh          = true
