# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/egress_vpc/main.tf ---

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "egress_vpc-${var.identifier}"
  }
}

# Default Security Group
# Ensuring that the default SG restricts all traffic (no ingress and egress rule). It is also not used in any resource
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.vpc.id
}

# SUBNETS
# TGW Subnets - for TGW ENIs
resource "aws_subnet" "vpc_tgw_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = [for i in range(0, 3) : cidrsubnet(var.cidr_block, 8, i)][count.index]
  availability_zone = var.azs_available[count.index]

  tags = {
    Name = "egress_vpc-tgw_subnet-${var.identifier}-${count.index + 1}"
  }
}

# Public subnets - if applicable
resource "aws_subnet" "vpc_public_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = [for i in range(129, 132) : cidrsubnet(var.cidr_block, 12, i)][count.index]
  availability_zone = var.azs_available[count.index]

  tags = {
    Name = "egress_vpc-public_subnet-${var.identifier}-${count.index + 1}"
  }
}

# IGW, EIPs and NAT GATEWAYs
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "IGW-egress_vpc-${var.identifier}"
  }
}

resource "aws_eip" "eip" {
  count = var.number_azs
  vpc   = true
}

resource "aws_nat_gateway" "natgw" {
  count         = var.number_azs
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.vpc_public_subnets[count.index].id

  tags = {
    Name = "natgw-egress_vpc-${var.identifier}-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# TRANSIT GATEWAY ATTACHMENT
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  subnet_ids         = [for subnet in aws_subnet.vpc_tgw_subnets : subnet.id]
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.vpc.id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "tgw_egress_attachment-${var.identifier}"
  }
}

# ROUTE TABLES
# TGW Subnet Route Table
resource "aws_route_table" "vpc_tgw_subnet_rt" {
  count  = var.number_azs
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "egress_vpc-tgw_subnet-rt-${var.identifier}-${count.index + 1}"
  }
}

resource "aws_route_table_association" "vpc_private_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.vpc_tgw_subnets[count.index].id
  route_table_id = aws_route_table.vpc_tgw_subnet_rt[count.index].id
}

# Public Subnet Route Tables - if applicable
resource "aws_route_table" "vpc_public_subnet_rt" {
  count  = var.number_azs
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "egress_vpc-public_subnet-rt-${var.identifier}-${count.index + 1}"
  }
}

resource "aws_route_table_association" "vpc_public_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.vpc_public_subnets[count.index].id
  route_table_id = aws_route_table.vpc_public_subnet_rt[count.index].id
}

# VPC ROUTES
# Traffic from TGW get to the NATGWs
resource "aws_route" "vpc_inspection_subnet_route_to_natgw" {
  count                  = var.number_azs
  route_table_id         = aws_route_table.vpc_tgw_subnet_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw[count.index].id
}

# Traffic to the Internet
resource "aws_route" "vpc_public_subnet_route_to_internet" {
  count                  = var.number_azs
  route_table_id         = aws_route_table.vpc_public_subnet_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
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
  name              = "egress_vpc-lg-vpc-flowlogs-${var.identifier}"
  retention_in_days = 7
  kms_key_id        = var.kms_key
}