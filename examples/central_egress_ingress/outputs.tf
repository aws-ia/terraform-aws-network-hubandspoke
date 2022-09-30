# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_egress_ingress/outputs.tf ---

output "transit_gateway_id" {
  description = "ID of the AWS Transit Gateway resource."
  value       = aws_ec2_transit_gateway.tgw.id
}

output "central_vpcs" {
  description = "Central VPCs created."
  value       = { for k, v in module.hub-and-spoke.central_vpcs : k => v.vpc_attributes.id }
}