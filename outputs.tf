# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

# AWS TRANSIT GATEWAY (if created)
output "transit_gateway" {
    description = "AWS Transit Gateway."
    value = try(aws_ec2_transit_gateway.tgw[0], null)
}

# CENTRAL VPCS
output "central_vpcs" {
    description = "Central VPCs created."
    value = module.central_vpcs
}

# TRANSIT GATEWAY CENTRAL VPCs ROUTE TABLES
output "tgw_rt_central_vpcs" {
    description = "Transit Gateway Route Tables associated to the Central VPC attachments."
    value = aws_ec2_transit_gateway_route_table.tgw_route_table
}

# TRANSIT GATEWAY SPOKE VPC ROUTE TABLE
output "tgw_rt_spoke_vpc" {
    description = "Transit Gateway Route Table associated to the Spoke VPCs."
    value = aws_ec2_transit_gateway_route_table.spokes_tgw_rt
}