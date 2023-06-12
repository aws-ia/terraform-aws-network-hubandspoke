# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_egress_ingress/main.tf ---

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

# Hub and Spoke module - we only centralize the Egress and Ingress traffic
module "hub-and-spoke" {
  source  = "aws-ia/network-hubandspoke/aws"
  version = "3.0.1"

  identifier         = var.identifier
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  network_definition = {
    type  = "PREFIX_LIST"
    value = aws_ec2_managed_prefix_list.network_prefix_list.id
  }

  central_vpcs = {
    egress = {
      name       = "egress-vpc"
      cidr_block = "10.10.0.0/24"
      az_count   = 2

      subnets = {
        public          = { netmask = 28 }
        transit_gateway = { netmask = 28 }
      }
    }

    ingress = {
      name       = "ingress-vpc"
      cidr_block = "10.20.0.0/24"
      az_count   = 2

      subnets = {
        public          = { netmask = 28 }
        transit_gateway = { netmask = 28 }
      }
    }
  }

  spoke_vpcs = {
    number_vpcs     = length(var.spoke_vpcs)
    routing_domains = ["prod"]
    vpc_information = { for k, v in module.spoke_vpcs : k => {
      vpc_id                        = v.vpc_attributes.id
      transit_gateway_attachment_id = v.transit_gateway_attachment_id
      routing_domain                = var.spoke_vpcs[k].routing_domain
    } }
  }
}

# Managed prefix list (to pass to the Hub and Spoke module)
resource "aws_ec2_managed_prefix_list" "network_prefix_list" {
  name           = "Network's Prefix List"
  address_family = "IPv4"
  max_entries    = 2
}

# Spoke VPCs 
module "spoke_vpcs" {
  for_each = var.spoke_vpcs
  source   = "aws-ia/vpc/aws"
  version  = "4.3.0"

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
    }
  }
}