# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/inspection/outputs.tf ---

output "inspection_vpc" {
  value       = module.central_inspection.inspection_vpc.vpc_id
  description = "VPC ID of the Inspection VPC."
}

output "spoke_vpcs" {
  value       = { for key, value in module.central_inspection.spoke_vpcs : key => value.vpc_id }
  description = "VPC IDs of the Spoke VPCs."
}

output "transit_gateway" {
  value       = module.central_inspection.transit_gateway
  description = "AWS Transit Gateway ID."
}

output "vpc_endpoints" {
  value       = { for key, value in module.central_inspection.decentralized_vpc_endpoints : key => value.vpc_endpoint_id }
  description = "Interface VPC endpoints created."
}

output "network_firewall" {
  value       = aws_networkfirewall_firewall.anfw.id
  description = "AWS Network Firewall ID."
}

output "ec2_instances" {
  value       = module.compute
  description = "EC2 instances created."
}