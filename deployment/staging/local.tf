locals {
  staging_rules = {
    "9100" : {
      type                     = "ingress"
      from_port                = 9100
      to_port                  = 9100
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.10.0.0/20"]
      source_security_group_id = null
      description              = ""
    },
    "management" : {
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.10.0.0/20"]
      source_security_group_id = null
      description              = "management VPC"
    },
    "all" : {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.20.0.0/19"]
      source_security_group_id = null
      description              = ""
    },
    "egress_v4" : {
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = ""
    },
    "egress_v6" : {
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = ["::/0"]
      cidr_blocks              = null
      source_security_group_id = null
      description              = ""
    }
  }

  staging_extra_rules = {
    "9100" : {
      type                     = "ingress"
      from_port                = 9100
      to_port                  = 9100
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.10.0.0/20"]
      source_security_group_id = null
      description              = ""
    },
    "all" : {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.20.0.0/19"]
      source_security_group_id = null
      description              = ""
    },
    "egress" : {
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = ""
    }
  }

  staging_nonui_rules = {
    "9100" : {
      type                     = "ingress"
      from_port                = 9100
      to_port                  = 9100
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.10.0.0/20"]
      source_security_group_id = null
      description              = ""
    },
    "all" : {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.20.0.0/19"]
      source_security_group_id = null
      description              = ""
    },
    "egress" : {
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = ""
    }
  }
}