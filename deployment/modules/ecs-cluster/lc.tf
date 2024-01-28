resource "aws_launch_configuration" "lc" {
  name_prefix                 = var.lc_name != null ? var.lc_name : var.name
  ebs_optimized               = var.lc_ebs_optimized
  iam_instance_profile        = var.lc_iam_instance_profile != null ? var.lc_iam_instance_profile : aws_iam_instance_profile.default[0].id
  image_id                    = var.lc_image_id
  instance_type               = var.lc_instance_type
  key_name                    = var.lc_key_name
  enable_monitoring           = var.lc_enable_monitoring
  associate_public_ip_address = var.lc_public_ip_address
  security_groups             = var.lc_security_groups
  user_data                   = templatefile("${path.module}/files/userdata.tftpl", { cluster_name = var.name, cloudwatch_group = aws_ssm_parameter.cloudwatch_config.name })

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = 3000
    throughput            = 125
    volume_size           = 100
    volume_type           = "gp3"
  }

  lifecycle {
    create_before_destroy = true
  }
}