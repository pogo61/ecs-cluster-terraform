locals {
  test_rules = {
    "cambridge" : {
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.98.0.0/16"]
      source_security_group_id = null
      description              = "Cambridge VPN"
    },
    "pgs1" : {
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.10.70.0/23"]
      source_security_group_id = null
      description              = "PGS"
    },
    "pgs2" : {
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.10.30.0/23"]
      source_security_group_id = null
      description              = "PGS"
    },
    "mqtt1" : {
      type                     = "ingress"
      from_port                = 1883
      to_port                  = 1883
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = null
      source_security_group_id = "sg-dbe18ba1"
      description              = "MQTT from Jenkins Node 8"
    },
    "mqtt2" : {
      type                     = "ingress"
      from_port                = 8883
      to_port                  = 8883
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = null
      source_security_group_id = "sg-dbe18ba1"
      description              = "MQTT from Jenkins Node 8"
    },
    "web" : {
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = null
      source_security_group_id = "sg-0bad3ccf3c2adad16"
      description              = "Jenkins WebTeamStatic Node"
    },
    "pgs3" : {
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.10.32.0/22"]
      source_security_group_id = null
      description              = "PGS"
    },
    "pgs4" : {
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.10.80.0/22"]
      source_security_group_id = null
      description              = "PGS"
    },
    "jenkins" : {
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = null
      source_security_group_id = "sg-b85b4fc5"
      description              = "Jenkins MK3"
    },
    "mailhog" : {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["52.211.201.165/32"]
      source_security_group_id = null
      description              = "NAT Gateway instance for Mailhog"
    },
    "all" : {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["10.15.0.0/20"]
      source_security_group_id = null
      description              = null
    },
    "egress" : {
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      ipv6_cidr_blocks         = null
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = null
    }
  }
}
