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

# Spoke VPC propagation (if Spoke VPCs should propagate in its own Segment Route Table)
resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_to_spokes_propagation" {
  for_each = {
    for k, v in var.segment_information : k => v.transit_gateway_attachment_id
    if var.tgw_attachment_propagation
  }

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_tgw_rt.id
}