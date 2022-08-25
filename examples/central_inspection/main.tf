# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/main.tf ---

# Hub and Spoke module - we only centralize the Inspection
module "hub-and-spoke" {
  source = "../.."

  identifier = var.identifier

  transit_gateway = {
    amazon_side_asn = 65000
  }

  central_vpcs = {
    inspection = {
      name       = "inspection-vpc"
      cidr_block = "10.10.0.0/24"
      az_count   = 2

      aws_network_firewall = {
        name       = "anfw-${var.identifier}"
        policy_arn = aws_networkfirewall_firewall_policy.anfw_policy.arn
      }

      subnets = {
        public = {
          netmask = 28
        }
        endpoints = {
          netmask = 28
        }
        transit_gateway = {
          netmask = 28
        }
      }
    }
  }

  spoke_vpcs = {
    network_prefix_list = aws_ec2_managed_prefix_list.network_prefix_list.id
    vpc_information = {
      production = { 
        for k, v in module.spoke_vpcs: k => {
          vpc_id = v.vpc_attributes.id
          transit_gateway_attachment_id = v.transit_gateway_attachment_id
        }
        if var.spoke_vpcs[k].type == "production"
      }
      nonproduction = {
        for k, v in module.spoke_vpcs: k => {
          vpc_id = v.vpc_attributes.id
          transit_gateway_attachment_id = v.transit_gateway_attachment_id
        }
        if var.spoke_vpcs[k].type == "nonproduction"
      }
    }
  }
}

# Spoke VPCs
module "spoke_vpcs" {
  for_each = var.spoke_vpcs

  source  = "aws-ia/vpc/aws"
  version = "= 2.5.0"

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.az_count

  subnets = {
    private = {
      name_prefix              = "private-subnet"
      netmask                  = each.value.private_subnet_netmask
      route_to_transit_gateway = "0.0.0.0/0"
    }
    endpoints = {
      name_prefix = "endpoints-subnet"
      netmask     = each.value.endpoints_subnet_netmask
    }
    transit_gateway = {
      name_prefix                                     = "tgw-subnet"
      netmask                                         = each.value.tgw_subnet_netmask
      transit_gateway_id                              = module.hub-and-spoke.transit_gateway.id
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }
  }
}

# Managed prefix list (to pass to the Hub and Spoke module)
resource "aws_ec2_managed_prefix_list" "network_prefix_list" {
  name           = "Network's Prefix List"
  address_family = "IPv4"
  max_entries    = length(keys(var.spoke_vpcs))
}

resource "aws_ec2_managed_prefix_list_entry" "entry" {
  for_each = var.spoke_vpcs

  cidr           = each.value.cidr_block
  description    = "${each.value.type}-${each.key}"
  prefix_list_id = aws_ec2_managed_prefix_list.network_prefix_list.id
}

# EC2 Instances (in each Spoke VPC)


# VPC Endpoints (in each Spoke VPC)


# IAM Resources

