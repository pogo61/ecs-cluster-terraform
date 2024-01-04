resource "aws_security_group" "sg" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id
  tags        = var.tags
}

output "security_group_id" {
  value = aws_security_group.sg.id
}