locals {
  management_rules = {
    "ssh" : {
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["192.168.100.170/32"]
      source_security_group_id = null
      description              = "SSH access"
    },
    "all1" : {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["172.31.11.116/32"]
      source_security_group_id = null
      description              = "allow all ingress"
    },
    "all2" : {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.10.0.0/20"]
      source_security_group_id = null
      description              = "allow all ingress"
    },
    "egress" : {
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = "allow all egress"
    }
  }
}