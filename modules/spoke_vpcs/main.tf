# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/spoke_vpcs/main.tf ---

resource "aws_ec2_transit_gateway_route_table" "spokes_tgw_rt" {
  transit_gateway_id = var.transit_gateway_id

  tags = {
    Name = "${var.segment_name}-spokes-tgw-rt-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "spokes_tgw_rt_association" {
  for_each = { 
    for k, v in try(var.segment_information.vpc_information, {}) : k => v.transit_gateway_attachment_id 
    if contains(keys(k), "transit_gateway_attachment_id") 
  }

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_tgw_rt.id
}