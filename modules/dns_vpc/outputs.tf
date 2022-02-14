# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/dns_vpc/outputs.tf ---

output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "DNS VPC ID."
}

output "tgw_subnets" {
  value       = aws_subnet.vpc_tgw_subnets.*.id
  description = "DNS VPC - TGW subnets."
}

output "dns_subnets" {
  value       = aws_subnet.vpc_dns_subnets.*.id
  description = "DNS VPC - DNS subnets."
}

output "tgw_attachment" {
  value       = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
  description = "DNS VPC - TGW VPC Attachment ID."
}

output "tgw_route_tables" {
  value       = aws_route_table.vpc_tgw_subnet_rt.*.id
  description = "DNS VPC - TGW subnet RTs"
}

output "dns_route_tables" {
  value       = aws_route_table.vpc_dns_subnet_rt.*.id
  description = "DNS VPC - DNS subnet RTs"
}

output "cloudwatch_flowlog_group" {
  value       = aws_cloudwatch_log_group.flowlogs_lg.*.id
  description = "Egress VPC - CloudWatch log group (VPC Flow Logs)"
}