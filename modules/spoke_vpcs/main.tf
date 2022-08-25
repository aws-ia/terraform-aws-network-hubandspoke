# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/spoke_vpcs/main.tf ---

# Segment's Route Table
resource "aws_ec2_transit_gateway_route_table" "spokes_tgw_rt" {
  transit_gateway_id = var.transit_gateway_id

  tags = {
    Name = "${var.segment_name}-spokes-tgw-rt-${var.identifier}"
  }
}

# Spoke VPC association
resource "aws_ec2_transit_gateway_route_table_association" "spokes_tgw_rt_association" {
  for_each = { for k, v in var.segment_information : k => v.transit_gateway_attachment_id }

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_tgw_rt.id
}

# Segment's CIDR block
# Managed prefix list (to pass to the Hub and Spoke module)
resource "aws_ec2_managed_prefix_list" "segment_prefix_list" {
  name           = "${var.segment_name}'s prefix list"
  address_family = "IPv4"
  max_entries    = length(keys(var.segment_information))
}

resource "aws_ec2_managed_prefix_list_entry" "entry" {
  for_each = data.aws_vpc.data_vpc

  cidr           = each.value.cidr_block_associations[0].cidr_block
  description    = "${var.segment_name}-${each.key}"
  prefix_list_id = aws_ec2_managed_prefix_list.segment_prefix_list.id
}

# VPC Data Source - to get each VPC CIDR block
data "aws_vpc" "data_vpc" {
  for_each = { for k, v in var.segment_information : k => v.vpc_id }

  id = each.value
}