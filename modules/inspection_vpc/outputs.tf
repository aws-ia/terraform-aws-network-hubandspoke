# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/inspection_vpc/outputs.tf ---

output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "Inspection VPC ID."
}

output "inspection_subnets" {
  value       = aws_subnet.vpc_inspection_subnets.*.id
  description = "Inspection VPC - Inspection subnets."
}

output "tgw_subnets" {
  value       = aws_subnet.vpc_tgw_subnets.*.id
  description = "Inspection VPC - TGW subnets."
}

output "public_subnets" {
  value       = aws_subnet.vpc_public_subnets.*.id
  description = "Inspection VPC - Public subnets."
}

output "natgw" {
  value       = aws_nat_gateway.natgw.*.id
  description = "Inspection VPC - NAT Gateways"
}

output "tgw_attachment" {
  value       = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
  description = "Inspection VPC - TGW VPC Attachment ID."
}

output "inspection_route_tables" {
  value       = aws_route_table.vpc_inspection_subnet_rt.*.id
  description = "Inspection VPC - Inspection subnet RTs"
}

output "tgw_route_tables" {
  value       = aws_route_table.vpc_tgw_subnet_rt.*.id
  description = "Inspection VPC - TGW subnet RTs"
}

output "public_route_tables" {
  value       = aws_route_table.vpc_public_subnet_rt.*.id
  description = "Inspection VPC - Public subnet RTs"
}

output "cloudwatch_flowlog_group" {
  value       = aws_cloudwatch_log_group.flowlogs_lg.*.id
  description = "Inspection VPC - CloudWatch log group (VPC Flow Logs)"
}