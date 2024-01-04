locals {
  sandbox-temp_rules = {
    "ingress" : {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = -1
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = null
    },
    "egress" : {
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = -1
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = null
    }
  }
}
