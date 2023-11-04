# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_shared_services/main.tf ---

# AWS Transit Gateway
resource "aws_ec2_transit_gateway" "tgw" {

  description                     = "Transit_Gateway-${var.identifier}"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  amazon_side_asn                 = 64515

  tags = {
    Name = "tgw-${var.identifier}"
  }
}

# Hub and Spoke module - we only centralize the Shared Services and Hybrid DNS VPCs
module "hub-and-spoke" {
  source = "../.."

  identifier         = var.identifier
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  network_definition = {
    type  = "CIDR"
    value = "10.0.0.0/14"
  }

  spoke_vpcs = {
    routing_domains = ["prod", "nonprod"]
    number_vpcs     = length(var.spoke_vpcs)
    vpc_information = { for k, v in module.spoke_vpcs : k => {
      vpc_id                        = v.vpc_attributes.id
      transit_gateway_attachment_id = v.transit_gateway_attachment_id
      routing_domain                = var.spoke_vpcs[k].domain
    } }
  }
}

# Spoke VPCs 
module "spoke_vpcs" {
  for_each = var.spoke_vpcs
  source   = "aws-ia/vpc/aws"
  version  = "4.4.0"

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  transit_gateway_routes = {
    workloads = "0.0.0.0/0"
  }

  subnets = {
    workload = { netmask = 28 }
    transit_gateway = {
      netmask                                         = 28
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false

      tags = {
        Name = "${each.key}-tgw-attachment"
      }
    }
  }
}