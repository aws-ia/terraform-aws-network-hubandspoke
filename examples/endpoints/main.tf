# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/endpoints/main.tf ---

module "central_endpoints" {
  source     = "../.."
  identifier = var.identifier
  aws_region = var.aws_region

  inspection_vpc = {
    create_vpc = false
  }

  egress_vpc = {
    create_vpc = false
  }
  ingress_vpc = {
    create_vpc = false
  }

  endpoints_vpc = {
    create_vpc     = true
    cidr_block     = var.cidr_blocks.endpoints_vpc
    number_azs     = var.number_azs
    enable_logging = false
    enable_dns     = false
  }

  dns_vpc = {
    create_vpc = false
  }

  spoke_vpcs = {
    spoke_1 = {
      cidr_block     = var.cidr_blocks.spoke_vpcs.spoke_1
      number_azs     = var.number_azs
      enable_logging = false
    }
    spoke_2 = {
      cidr_block     = var.cidr_blocks.spoke_vpcs.spoke_2
      number_azs     = var.number_azs
      enable_logging = false
    }
  }
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
  for_each       = module.central_endpoints.spoke_vpcs
  source         = "./modules/compute"
  identifier     = var.identifier
  vpc_name       = each.key
  vpc_id         = each.value.vpc_id
  ami            = data.aws_ami.amazon_linux.id
  instance_type  = var.instance_type
  subnets        = each.value.private_subnets
  role_id        = module.iam.ec2_ssm_role
  sg_information = local.security_groups.instance
}

# IAM ROLES (EC2 INSTANCE AND VPC FLOW LOGS) AND KMS KEY
module "iam" {
  source     = "./modules/iam"
  identifier = var.identifier
}

# S3 VPC ENDPOINT AND PRIVATE HOSTED ZONE
# VPC endpoint in Endpoints VPC
resource "aws_vpc_endpoint" "endpoint" {
  for_each            = local.endpoint_service_names
  vpc_id              = module.central_endpoints.endpoints_vpc.vpc_id
  service_name        = each.value.name
  vpc_endpoint_type   = each.value.type
  subnet_ids          = module.central_endpoints.endpoints_vpc.endpoints_subnets
  security_group_ids  = [module.central_endpoints.centralized_vpc_endpoints.endpoint_sg]
  private_dns_enabled = each.value.private_dns
}

# Private Hosted Zone
resource "aws_route53_zone" "private_hosted_zone" {
  for_each = local.endpoint_service_names
  name     = each.value.phz_name

  dynamic "vpc" {
    for_each = module.central_endpoints.spoke_vpcs
    content {
      vpc_id = vpc.value.vpc_id
    }
  }
}

# DNS RECORDS POINTING TO THE VPC ENDPOINTS
resource "aws_route53_record" "endpoint_record" {
  for_each = local.endpoint_service_names
  zone_id  = aws_route53_zone.private_hosted_zone[each.key].id
  name     = ""
  type     = "A"

  alias {
    name                   = aws_vpc_endpoint.endpoint[each.key].dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.endpoint[each.key].dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}

# This specific resource is for the PHZs that need one extra alias with a "*" (for example, Amazon S3)
resource "aws_route53_record" "endpoint_wildcard_record" {
  for_each = local.endpoint_service_names
  zone_id  = aws_route53_zone.private_hosted_zone[each.key].id
  name     = "*"
  type     = "A"

  alias {
    name                   = aws_vpc_endpoint.endpoint[each.key].dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.endpoint[each.key].dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}