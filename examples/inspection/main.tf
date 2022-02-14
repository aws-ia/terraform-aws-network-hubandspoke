# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/inspection/main.tf ---

module "central_inspection" {
  source     = "../.."
  identifier = var.identifier
  aws_region = var.aws_region

  log_variables = {
    vpc_flowlog_role = module.iam_kms.vpc_flowlog_role
    kms_key          = module.iam_kms.kms_arn
  }

  inspection_vpc = {
    create_vpc     = true
    cidr_block     = var.cidr_blocks.inspection_vpc
    number_azs     = var.number_azs
    enable_logging = true
    enable_egress  = true
  }

  egress_vpc = {
    create_vpc = false
  }
  ingress_vpc = {
    create_vpc = false
  }
  endpoints_vpc = {
    create_vpc = false
  }
  dns_vpc = {
    create_vpc = false
  }

  spoke_vpcs = {
    spoke_1 = {
      cidr_block     = var.cidr_blocks.spoke_vpcs.spoke_1
      number_azs     = var.number_azs
      enable_logging = true
    }
  }
}

# AWS NETWORK FIREWALL RESOURCES
# AWS Network Firewall
resource "aws_networkfirewall_firewall" "anfw" {
  name                = "ANFW-${var.identifier}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.anfw_policy.arn
  vpc_id              = module.central_inspection.inspection_vpc.vpc_id

  dynamic "subnet_mapping" {
    for_each = module.central_inspection.inspection_vpc.inspection_subnets

    content {
      subnet_id = subnet_mapping.value
    }
  }
}

# VPC route (0.0.0.0/0) from TGW ENIs to firewall endpoints (Inspection VPC)
resource "aws_route" "tgw_to_firewall_endpoint" {
  count                  = var.number_azs
  route_table_id         = module.central_inspection.inspection_vpc.tgw_route_tables[count.index]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = [for i in aws_networkfirewall_firewall.anfw.firewall_status[0].sync_states : i.attachment[0].endpoint_id][count.index]
}

# VPC route (10.0.0.0/8) from firewall endpoints to TGW ENIs (Inspection VPC)
resource "aws_route" "firewall_to_tgw_endpoint" {
  count                  = var.number_azs
  route_table_id         = module.central_inspection.inspection_vpc.inspection_route_tables[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = module.central_inspection.transit_gateway
}

# VPC route (10.0.0.0/8) from IGW to the firewall endpoints
resource "aws_route" "natgw_to_firewall" {
  count                  = var.number_azs
  route_table_id         = module.central_inspection.inspection_vpc.public_route_tables[count.index]
  destination_cidr_block = "10.0.0.0/8"
  vpc_endpoint_id        = [for i in aws_networkfirewall_firewall.anfw.firewall_status[0].sync_states : i.attachment[0].endpoint_id][count.index]
}

# EC2 INSTANCES RESOURCES
# Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }
}

# EC2 instances and Security Groups
module "compute" {
  for_each       = module.central_inspection.spoke_vpcs
  source         = "./modules/compute"
  identifier     = var.identifier
  vpc_name       = each.key
  vpc_id         = each.value.vpc_id
  ami            = data.aws_ami.amazon_linux.id
  instance_type  = var.instance_type
  subnets        = each.value.private_subnets
  role_id        = module.iam_kms.ec2_ssm_role
  sg_information = local.security_groups.instance
}

# IAM ROLES (EC2 INSTANCE AND VPC FLOW LOGS) AND KMS KEY
module "iam_kms" {
  source     = "./modules/iam_kms"
  identifier = var.identifier
}
