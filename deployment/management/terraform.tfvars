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
    lc_iam_instance_profile = "arn:aws:iam::629809936211:instance-profile/ecsInstance-ManagementCluster",
  }
}

instance_refresh          = true
teams_webhook_url_testers = "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/55dd5e78d4c043b599e17b1983b3a363/25a519c0-d1aa-419b-b691-07e22a206b4e"
report_cron_schedule      = "cron(0 8 ? * MON *)"