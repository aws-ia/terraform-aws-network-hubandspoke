# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/main.tf ---

# Hub and Spoke module - we only centralize the Inspection
module "hub-and-spoke" {
  source  = "aws-ia/network-hubandspoke"
  version = "2.0.0"

  identifier = var.identifier
  transit_gateway_attributes = {
    name            = "tgw-${var.identifier}"
    description     = "Transit_Gateway-${var.identifier}"
    amazon_side_asn = 65000
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
        name       = "anfw-${var.identifier}"
        policy_arn = aws_networkfirewall_firewall_policy.anfw_policy.arn
      }

      subnets = {
        public          = { netmask = 28 }
        endpoints       = { netmask = 28 }
        transit_gateway = { netmask = 28 }
      }
    }
  }

  spoke_vpcs = {
    number_vpcs     = length(var.spoke_vpcs)
    routing_domains = ["prod", "nonprod"]
    vpc_information = { for k, v in module.spoke_vpcs : k => {
      vpc_id                        = v.vpc_attributes.id
      transit_gateway_attachment_id = v.transit_gateway_attachment_id
      routing_domain                = var.spoke_vpcs[k].routing_domain
    } }
  }
}

# Spoke VPCs 
module "spoke_vpcs" {
  for_each = var.spoke_vpcs
  source   = "aws-ia/vpc/aws"
  version  = "3.1.0"

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = module.hub-and-spoke.transit_gateway.id
  transit_gateway_routes = {
    workloads = "0.0.0.0/0"
  }

  subnets = {
    workload = { netmask = 28 }
    transit_gateway = {
      netmask                                         = 28
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }
  }
}