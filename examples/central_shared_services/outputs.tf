# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_shared_services/outputs.tf ---

output "transit_gateway" {
  description = "Transit Gateway ID."
  value       = aws_ec2_transit_gateway.tgw.id
}

output "vpcs" {
  description = "VPCs created."
  value = {
    central_vpcs = { for k, v in module.hub-and-spoke.central_vpcs : k => v.vpc_attributes.id }
    spoke_vpcs   = { for k, v in module.spoke_vpcs : k => v.vpc_attributes.id }
  }
}

output "transit_gateway_route_tables" {
  description = "Transit Gateway Route Tables."
  value = {
    central_vpcs = { for k, v in module.hub-and-spoke.transit_gateway_route_tables.central_vpcs : k => v.id }
    spoke_vpcs   = { for k, v in module.hub-and-spoke.transit_gateway_route_tables.spoke_vpcs : k => v.id }
  }
}

output "ec2_instances" {
  description = "EC2 instances created."
  value       = { for k, v in module.compute : k => v.ec2_instances.*.id }
}

output "vpc_endpoints" {
  description = "SSM VPC endpoints created."
  value       = module.vpc_endpoints.endpoint_ids
}

output "private_hosted_zones" {
    description = "Private Hosted Zones created."
    value = module.phz.private_hosted_zones
}