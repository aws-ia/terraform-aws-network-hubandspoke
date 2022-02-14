# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/spoke_vpc/main.tf ---

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.vpc_name}-${var.identifier}"
  }
}

# Default Security Group
# Ensuring that the default SG restricts all traffic (no ingress and egress rule). It is also not used in any resource
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.vpc.id
}

# SUBNETS
# Private Subnets - to place the workload (instances, containers, etc.)
resource "aws_subnet" "vpc_private_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = [for i in range(0, 3) : cidrsubnet(var.cidr_block, 8, i)][count.index]
  availability_zone = var.azs_available[count.index]

  tags = {
    Name = "${var.vpc_name}-private_subnet-${var.identifier}-${count.index + 1}"
  }
}

# TGW Subnets - for TGW ENIs
resource "aws_subnet" "vpc_tgw_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = [for i in range(129, 132) : cidrsubnet(var.cidr_block, 12, i)][count.index]
  availability_zone = var.azs_available[count.index]

  tags = {
    Name = "${var.vpc_name}-tgw_subnet-${var.identifier}-${count.index + 1}"
  }
}

# VPC endpoints subnets - if no VPC endpoint centralization
resource "aws_subnet" "vpc_endpoints_subnets" {
  count             = var.endpoints_vpc_created ? 0 : var.number_azs
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = [for i in range(200, 203) : cidrsubnet(var.cidr_block, 12, i)][count.index]
  availability_zone = var.azs_available[count.index]

  tags = {
    Name = "${var.vpc_name}-endpoints_subnet-${var.identifier}-${count.index + 1}"
  }
}

# TRANSIT GATEWAY ATTACHMENT
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  subnet_ids         = [for subnet in aws_subnet.vpc_tgw_subnets : subnet.id]
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.vpc.id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "tgw_${var.vpc_name}_attachment-${var.identifier}"
  }
}

# ROUTE TABLES
# Private Subnet Route Table
resource "aws_route_table" "vpc_private_subnet_rt" {
  count  = var.number_azs
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-private_subnet-rt-${var.identifier}-${count.index + 1}"
  }
}

resource "aws_route_table_association" "vpc_private_subnet_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.vpc_private_subnets[count.index].id
  route_table_id = aws_route_table.vpc_private_subnet_rt[count.index].id
}

# TGW Subnet Route Table
resource "aws_route_table" "vpc_tgw_subnet_rt" {
  count  = var.number_azs
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-tgw_subnet-rt-${var.identifier}-${count.index + 1}"
  }
}

resource "aws_route_table_association" "vpc_tgw_subnet_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.vpc_tgw_subnets[count.index].id
  route_table_id = aws_route_table.vpc_tgw_subnet_rt[count.index].id
}

# VPC Endpoints Subnet Route Tables - if applicable
resource "aws_route_table" "vpc_endpoints_subnet_rt" {
  count  = var.endpoints_vpc_created ? 0 : var.number_azs
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-endpoints_subnet-rt-${var.identifier}-${count.index + 1}"
  }
}

resource "aws_route_table_association" "vpc_endpoints_rt_assoc" {
  count          = var.endpoints_vpc_created ? 0 : var.number_azs
  subnet_id      = aws_subnet.vpc_endpoints_subnets[count.index].id
  route_table_id = aws_route_table.vpc_endpoints_subnet_rt[count.index].id
}

# VPC ROUTES
# Private subnets communication out of the VPC via the TGW
resource "aws_route" "vpc_private_subnet_route_to_tgw" {
  count                  = var.number_azs
  route_table_id         = aws_route_table.vpc_private_subnet_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw_id
}

# VPC FLOW LOGS (if enabled)
# VPC Flow Log Resource
resource "aws_flow_log" "vpc_flowlog" {
  count           = var.enable_logging ? 1 : 0
  iam_role_arn    = var.vpc_flowlog_role
  log_destination = aws_cloudwatch_log_group.flowlogs_lg[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "flowlogs_lg" {
  count             = var.enable_logging ? 1 : 0
  name              = "${var.vpc_name}-lg-vpc-flowlogs-${var.identifier}"
  retention_in_days = 7
  kms_key_id        = var.kms_key
}