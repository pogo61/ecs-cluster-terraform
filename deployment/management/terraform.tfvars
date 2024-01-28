environment = "management"
ecs_clusters = {
  "ManagementCluster" = {
    asg_name                = "ECS ManagementCluster",
    asg_desired_capacity    = 1
    asg_min_size            = 1
    asg_max_size            = 1
    lc_instance_type        = "m5.large",
    lc_key_name             = "devops-2020-01",
    lc_security_groups      = ["sg-58cc4922", "sg-fec14484"],
    lc_iam_instance_profile = "arn:aws:iam:::instance-profile/ecsInstance-ManagementCluster",
  }
}

instance_refresh          = true
teams_webhook_url_testers = ""
