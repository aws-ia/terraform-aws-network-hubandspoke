# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_shared_services/outputs.tf ---

output "transit_gateway_id" {
  description = "ID of the AWS Transit Gateway resource."
  value       = aws_ec2_transit_gateway.tgw.id
}

output "tgw_route_tables" {
  description = "Transit Gateway route table IDs."
  value       = { for k, v in module.hub-and-spoke.transit_gateway_route_tables.spoke_vpcs : k => v.id }
}

output "spoke_vpcs" {
  description = "Spoke VPCs created."
  value       = { for k, v in module.spoke_vpcs : k => v.vpc_attributes.id }
}