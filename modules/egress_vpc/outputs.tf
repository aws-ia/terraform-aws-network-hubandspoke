# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/egress_vpc/outputs.tf ---

output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "Egress VPC ID."
}

output "tgw_subnets" {
  value       = aws_subnet.vpc_tgw_subnets.*.id
  description = "Egress VPC - TGW subnets."
}

output "public_subnets" {
  value       = aws_subnet.vpc_public_subnets.*.id
  description = "Egress VPC - Public subnets."
}

output "natgw" {
  value       = aws_nat_gateway.natgw.*.id
  description = "Egress VPC - NAT Gateways"
}

output "tgw_attachment" {
  value       = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
  description = "Egress VPC - TGW VPC Attachment ID."
}

output "tgw_route_tables" {
  value       = aws_route_table.vpc_tgw_subnet_rt.*.id
  description = "Egress VPC - TGW subnet RTs"
}

output "public_route_tables" {
  value       = aws_route_table.vpc_public_subnet_rt.*.id
  description = "Egress VPC - Public subnet RTs"
}

output "cloudwatch_flowlog_group" {
  value       = aws_cloudwatch_log_group.flowlogs_lg.*.id
  description = "Egress VPC - CloudWatch log group (VPC Flow Logs)"
}