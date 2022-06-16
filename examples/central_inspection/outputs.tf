# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/outputs.tf ---

output "transit_gateway" {
  description = "Transit Gateway ID."
  value       = aws_ec2_transit_gateway.tgw.id
}

output "central_vpcs" {
  description = "Central VPCs created (ID)."
  value       = { for k, v in module.hub-and-spoke.central_vpcs : k => v.vpc_attributes.id }
}

output "tgw_rt_central_vpcs" {
  description = "Transit Gateway Route Tables associated to Central VPC attachments."
  value       = { for k, v in module.hub-and-spoke.tgw_rt_central_vpcs : k => v.id }
}

output "tgw_rt_spoke_vpcs" {
  description = "Transit Gateway Route Table associated to the Spoke VPC attachments."
  value       = module.hub-and-spoke.tgw_rt_spoke_vpc.id
}