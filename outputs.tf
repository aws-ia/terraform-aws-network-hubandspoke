# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

# AWS TRANSIT GATEWAY (if created)
output "transit_gateway" {
  description = "AWS Transit Gateway."
  value       = try(aws_ec2_transit_gateway.tgw[0], null)
}

# CENTRAL VPCS
output "central_vpcs" {
  description = "Central VPCs created."
  value       = module.central_vpcs
}

# TRANSIT GATEWAY ROUTE TABLES
output "transit_gateway_route_tables" {
  description = "Transit Gateway Route Tables."
  value = {
    central_vpcs = aws_ec2_transit_gateway_route_table.tgw_route_table
    spoke_vpcs   = local.vpc_information ? { for k, v in module.spoke_vpcs : k => v.transit_gateway_spoke_rt } : null
  }
}

# AWS NETWORK FIREWALL RESOURCE (IF CREATED)
output "aws_network_firewall" {
  description = "AWS Network Firewall."
  value       = local.create_anfw ? module.aws_network_firewall[0].aws_network_firewall : null
}