# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

output "transit_gateway" {
  value       = aws_ec2_transit_gateway.tgw.id
  description = "Transit Gateway ID."
}

output "inspection_vpc" {
  value       = var.inspection_vpc.create_vpc ? module.inspection_vpc[0] : null
  description = "Inspection VPC resources."
}

output "egress_vpc" {
  value       = var.egress_vpc.create_vpc ? module.egress_vpc[0] : null
  description = "Egress VPC resources."
}

output "ingress_vpc" {
  value       = var.ingress_vpc.create_vpc ? module.ingress_vpc[0] : null
  description = "Ingress VPC resources."
}

output "endpoints_vpc" {
  value       = var.endpoints_vpc.create_vpc ? module.endpoints_vpc[0] : null
  description = "Endpoints VPC resources."
}

output "dns_vpc" {
  value       = var.dns_vpc.create_vpc ? module.dns_vpc[0] : null
  description = "DNS VPC resources."
}

output "spoke_vpcs" {
  value       = length(var.spoke_vpcs) == 0 ? null : module.spoke_vpcs
  description = "Spoke VPCs resources."
}

output "centralized_vpc_endpoints" {
  value       = var.endpoints_vpc.create_vpc ? module.centralized_endpoints[0] : null
  description = "VPC endpoints (centralized in Endpoints VPC)"
}

output "decentralized_vpc_endpoints" {
  value       = var.endpoints_vpc.create_vpc || length(var.spoke_vpcs) == 0 ? null : module.decentralized_endpoints
  description = "VPC endpoints (decentralized in Spoke VPCs)"
}

output "private_hosted_zones" {
  value       = var.endpoints_vpc.create_vpc ? module.phz[0] : null
  description = "Private Hosted Zones (if centralized VPC endpoints)"
}
