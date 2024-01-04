resource "aws_security_group_rule" "sg_rule" {
  for_each = var.rules

  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  ipv6_cidr_blocks         = each.value.ipv6_cidr_blocks
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  security_group_id        = aws_security_group.sg.id
  description              = each.value.description
}