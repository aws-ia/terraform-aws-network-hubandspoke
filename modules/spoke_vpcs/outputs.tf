# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/spoke_vpcs/outputs.tf ---

output "transit_gateway_spoke_rt" {
  description = "Segment's Spoke Transit Gateway Route Table."
  value       = aws_ec2_transit_gateway_route_table.spokes_tgw_rt
}

