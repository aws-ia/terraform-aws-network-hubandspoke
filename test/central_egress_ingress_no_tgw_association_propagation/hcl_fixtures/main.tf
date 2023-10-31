# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

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

# Managed prefix list (to pass to the Hub and Spoke module)
resource "aws_ec2_managed_prefix_list" "network_prefix_list" {
  name           = "Network's Prefix List"
  address_family = "IPv4"
  max_entries    = 2
}
