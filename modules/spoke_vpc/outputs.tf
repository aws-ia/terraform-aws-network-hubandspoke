# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/spoke_vpc/outputs.tf ---

output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "Spoke VPC ID."
}

output "private_subnets" {
  value       = aws_subnet.vpc_private_subnets.*.id
  description = "Spoke VPC - Private subnets."
}

output "tgw_subnets" {
  value       = aws_subnet.vpc_tgw_subnets.*.id
  description = "Spoke VPC - TGW subnets."
}

output "endpoints_subnets" {
  value       = aws_subnet.vpc_endpoints_subnets.*.id
  description = "Spoke VPC - Endpoints subnets."
}

output "tgw_attachment" {
  value       = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
  description = "Spoke VPC - TGW VPC Attachment ID."
}

output "private_route_tables" {
  value       = aws_route_table.vpc_private_subnet_rt.*.id
  description = "Spoke VPC - Private subnet RTs"
}

output "tgw_route_tables" {
  value       = aws_route_table.vpc_tgw_subnet_rt.*.id
  description = "Spoke VPC - TGW subnet RTs"
}

output "endpoints_route_tables" {
  value       = aws_route_table.vpc_endpoints_subnet_rt.*.id
  description = "Spoke VPC - Endpoints subnet RTs"
}

output "cloudwatch_flowlog_group" {
  value       = aws_cloudwatch_log_group.flowlogs_lg.*.id
  description = "Endpoints VPC - CloudWatch log group (VPC Flow Logs)"
}