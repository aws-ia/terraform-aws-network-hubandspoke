# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/outputs.tf ---

output "transit_gateway" {
  description = "Transit Gateway ID."
  value       = module.hub-and-spoke.transit_gateway.id
}

output "vpcs" {
  description = "VPCs created."
  value = {
    central_vpcs = { for k, v in module.hub-and-spoke.central_vpcs : k => v.vpc_attributes.id }
    spoke_vpcs = { for k, v in module.spoke_vpcs: k => v.vpc_attributes.id }
  }
}

output "transit_gateway_route_tables" {
  description = "Transit Gateway Route Tables."
  value = {
    central_vpcs = { for k, v in module.hub-and-spoke.transit_gateway_route_tables.central_vpcs: k => v.id }
    spoke_vpcs = { for k, v in module.hub-and-spoke.transit_gateway_route_tables.spoke_vpcs: k => v.id }
  }
}

output "network_firewall" {
  description = "AWS Network Firewall ID."
  value = module.hub-and-spoke.aws_network_firewall.id
}