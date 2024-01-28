#environment = "dev"
ecs_clusters = {
  "Test" = {
    asg_name                  = "ECS Test"
    lc_name                   = "ECS Test",
    lc_instance_type          = "r5a.large",
    lc_key_name               = "devops-2021-02",
    lc_security_groups        = ["sg-1656046c", "sg-4544fe3f"],
    lc_iam_instance_profile   = "arn:aws:iam::095955279155:instance-profile/ecsInstance-Test",
    lc_enable_monitoring      = true,
    datadog_enable_monitoring = "Yes",
    asg_desired_capacity      = 4,
    asg_min_size              = 1,
    asg_max_size              = 4,
    create_auto_stop_table    = true
    asg_capacity_rebalance    = true
  }
  "Test-Checkit-Tom" = {
    asg_name                = null,
    lc_name                 = null,
    lc_instance_type        = "t3a.medium",
    lc_key_name             = "devops-2021-02",
    lc_security_groups      = ["sg-1656046c", "sg-4544fe3f"],
    lc_iam_instance_profile = "arn:aws:iam::095955279155:instance-profile/ecsInstance-Test",
    asg_desired_capacity    = 1,
    asg_min_size            = 1,
    asg_max_size            = 1,
    create_auto_stop_table  = false
    asg_capacity_rebalance  = false
  }
}

# public: Devops
teams_webhook_url_public = "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/4bbb0c3b69884668b18063ee82c905a9/25a519c0-d1aa-419b-b691-07e22a206b4e"

# private: DevOps-Activity-Feed
teams_webhook_url_private = "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/55dd5e78d4c043b599e17b1983b3a363/25a519c0-d1aa-419b-b691-07e22a206b4e"

# testers: Test-Alerts
teams_webhook_url_testers = "https://checkitltd.webhook.office.com/webhookb2/58f5eb66-419c-4135-b5ec-250934072aae@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/861c67091826426caa5aae81d6c6639c/25a519c0-d1aa-419b-b691-07e22a206b4e"

image_does_not_exist_action = "STOP_SERVICE"
cluster_unstable_action     = "CONTINUE"
instance_refresh            = true
report_cron_schedule        = "cron(0 8 ? * MON *)"
