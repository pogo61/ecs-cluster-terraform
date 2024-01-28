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
teams_webhook_url_public  = "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/9368eb879d3d4a50925cb4f1c03b93ce/25a519c0-d1aa-419b-b691-07e22a206b4e"
teams_webhook_url_private = "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/9368eb879d3d4a50925cb4f1c03b93ce/25a519c0-d1aa-419b-b691-07e22a206b4e"
teams_webhook_url_testers = "https://checkitltd.webhook.office.com/webhookb2/c5d24509-3944-485a-b06e-37ac27294f92@c766b904-8fbf-43be-a845-0cab82a691e9/IncomingWebhook/9368eb879d3d4a50925cb4f1c03b93ce/25a519c0-d1aa-419b-b691-07e22a206b4e"