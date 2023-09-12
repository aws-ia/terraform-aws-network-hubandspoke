# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/main.tf ---

# Hub and Spoke module - we only centralize the Inspection
module "hub-and-spoke" {
  source  = "aws-ia/network-hubandspoke/aws"
  version = "3.0.2"

  identifier = var.identifier
  transit_gateway_attributes = {
    name            = "tgw-${var.identifier}"
    description     = "Transit_Gateway-${var.identifier}"
    amazon_side_asn = 65000

    tags = {
      team = "networking"
    }
  }

  network_definition = {
    type  = "CIDR"
    value = "10.0.0.0/8"
  }

  central_vpcs = {
    inspection = {
      name            = "inspection-vpc"
      cidr_block      = "10.10.0.0/24"
      az_count        = 2
      inspection_flow = "north-south"

      aws_network_firewall = {
        name        = "anfw-${var.identifier}"
        description = "AWS Network Firewall - ${var.identifier}"
        policy_arn  = aws_networkfirewall_firewall_policy.anfw_policy.arn
      }

      subnets = {
        public          = { netmask = 28 }
        endpoints       = { netmask = 28 }
        transit_gateway = { netmask = 28 }
      }

      tags = {
        team = "security"
      }
    }
  }

  tags = {
    project = "central-inspection"
  }
}