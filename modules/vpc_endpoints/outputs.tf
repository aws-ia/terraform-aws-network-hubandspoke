# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/vpc_endpoints/outputs.tf ---

output "vpc_endpoint_id" {
  value       = { for key, value in aws_vpc_endpoint.endpoint : key => value.id }
  description = "VPC endpoints IDs."
}

output "vpc_endpoint_dns" {
  value       = { for key, value in aws_vpc_endpoint.endpoint : key => value.dns_entry[0] }
  description = "VPC endpoints DNS information."
}

output "endpoint_sg" {
  value       = aws_security_group.endpoints_vpc_sg.id
  description = "Security Group created for the VPC endpoints (allowing HTTPS traffic)."
}