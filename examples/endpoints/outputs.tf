# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/endpoints/outputs.tf ---

output "endpoints_vpc" {
  value       = module.central_endpoints.endpoints_vpc.vpc_id
  description = "VPC ID of the Inspection VPC."
}

output "spoke_vpcs" {
  value       = { for key, value in module.central_endpoints.spoke_vpcs : key => value.vpc_id }
  description = "VPC IDs of the Spoke VPCs."
}

output "transit_gateway" {
  value       = module.central_endpoints.transit_gateway
  description = "AWS Transit Gateway ID."
}

output "vpc_endpoints" {
  value       = module.central_endpoints.centralized_vpc_endpoints.vpc_endpoint_id
  description = "Interface VPC endpoints created."
}

output "ec2_instances" {
  value       = module.compute
  description = "EC2 instances created."
}

output "extra_vpc_endpoint" {
  value       = { for key, value in aws_vpc_endpoint.endpoint : key => value.id }
  description = "S3 VPC Endpoint."
}