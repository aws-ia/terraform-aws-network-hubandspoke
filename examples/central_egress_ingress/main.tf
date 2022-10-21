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
  source  = "aws-ia/network-hubandspoke"
  version = "1.0.1"

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
}

# Managed prefix list (to pass to the Hub and Spoke module)
resource "aws_ec2_managed_prefix_list" "network_prefix_list" {
  name           = "Network's Prefix List"
  address_family = "IPv4"
  max_entries    = 2
}