# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# List of AZs available in the AWS Region
data "aws_availability_zones" "available" {
  state = "available"
}

# AWS Transit Gateway Resources
resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "Transit-Gateway-${var.identifier}"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "transit-gateway-${var.identifier}"
  }
}

module "tgw_rt" {
  source     = "./modules/tgw_rt"
  identifier = var.identifier

  inspection_vpc = var.inspection_vpc.create_vpc
  egress_vpc     = var.egress_vpc.create_vpc
  ingress_vpc    = var.ingress_vpc.create_vpc
  endpoints_vpc  = var.endpoints_vpc.create_vpc
  dns_vpc        = var.dns_vpc.create_vpc

  tgw_id                    = aws_ec2_transit_gateway.tgw.id
  inspection_tgw_attachment = var.inspection_vpc.create_vpc ? module.inspection_vpc[0].tgw_attachment : ""
  egress_tgw_attachment     = var.egress_vpc.create_vpc ? module.egress_vpc[0].tgw_attachment : ""
  ingress_tgw_attachment    = var.ingress_vpc.create_vpc ? module.ingress_vpc[0].tgw_attachment : ""
  endpoints_tgw_attachment  = var.endpoints_vpc.create_vpc ? module.endpoints_vpc[0].tgw_attachment : ""
  dns_tgw_attachment        = var.dns_vpc.create_vpc ? module.dns_vpc[0].tgw_attachment : ""
  spoke_tgw_attachments     = { for key, value in module.spoke_vpcs : key => value.tgw_attachment }
}

# VPCs
# Inspection VPC - with our without Egress Traffic
module "inspection_vpc" {
  count            = var.inspection_vpc.create_vpc ? 1 : 0
  source           = "./modules/inspection_vpc"
  identifier       = var.identifier
  cidr_block       = var.inspection_vpc.cidr_block
  number_azs       = var.inspection_vpc.number_azs
  azs_available    = data.aws_availability_zones.available.names
  enable_logging   = var.inspection_vpc.enable_logging
  enable_egress    = var.inspection_vpc.enable_egress
  tgw_id           = aws_ec2_transit_gateway.tgw.id
  vpc_flowlog_role = var.inspection_vpc.enable_logging ? var.log_variables.vpc_flowlog_role : ""
  kms_key          = var.inspection_vpc.enable_logging ? var.log_variables.kms_key : ""
}

# Egress VPC
module "egress_vpc" {
  count            = var.egress_vpc.create_vpc ? 1 : 0
  source           = "./modules/egress_vpc"
  identifier       = var.identifier
  cidr_block       = var.egress_vpc.cidr_block
  number_azs       = var.egress_vpc.number_azs
  azs_available    = data.aws_availability_zones.available.names
  enable_logging   = var.egress_vpc.enable_logging
  tgw_id           = aws_ec2_transit_gateway.tgw.id
  vpc_flowlog_role = var.egress_vpc.enable_logging ? var.log_variables.vpc_flowlog_role : ""
  kms_key          = var.egress_vpc.enable_logging ? var.log_variables.kms_key : ""
}

# Ingress VPC
module "ingress_vpc" {
  count            = var.ingress_vpc.create_vpc ? 1 : 0
  source           = "./modules/ingress_vpc"
  identifier       = var.identifier
  cidr_block       = var.ingress_vpc.cidr_block
  number_azs       = var.ingress_vpc.number_azs
  azs_available    = data.aws_availability_zones.available.names
  enable_logging   = var.ingress_vpc.enable_logging
  tgw_id           = aws_ec2_transit_gateway.tgw.id
  vpc_flowlog_role = var.ingress_vpc.enable_logging ? var.log_variables.vpc_flowlog_role : ""
  kms_key          = var.ingress_vpc.enable_logging ? var.log_variables.kms_key : ""
}

# Inspection VPC - with our without subnets for DNS forwarders
module "endpoints_vpc" {
  count            = var.endpoints_vpc.create_vpc ? 1 : 0
  source           = "./modules/endpoints_vpc"
  identifier       = var.identifier
  cidr_block       = var.endpoints_vpc.cidr_block
  number_azs       = var.endpoints_vpc.number_azs
  azs_available    = data.aws_availability_zones.available.names
  enable_logging   = var.endpoints_vpc.enable_logging
  enable_dns       = var.endpoints_vpc.enable_dns
  tgw_id           = aws_ec2_transit_gateway.tgw.id
  vpc_flowlog_role = var.endpoints_vpc.enable_logging ? var.log_variables.vpc_flowlog_role : ""
  kms_key          = var.endpoints_vpc.enable_logging ? var.log_variables.kms_key : ""
}

# DNS VPC
module "dns_vpc" {
  count            = var.dns_vpc.create_vpc ? 1 : 0
  source           = "./modules/dns_vpc"
  identifier       = var.identifier
  cidr_block       = var.dns_vpc.cidr_block
  number_azs       = var.dns_vpc.number_azs
  azs_available    = data.aws_availability_zones.available.names
  enable_logging   = var.dns_vpc.enable_logging
  tgw_id           = aws_ec2_transit_gateway.tgw.id
  vpc_flowlog_role = var.dns_vpc.enable_logging ? var.log_variables.vpc_flowlog_role : ""
  kms_key          = var.dns_vpc.enable_logging ? var.log_variables.kms_key : ""
}

# Spoke VPCs
module "spoke_vpcs" {
  for_each              = var.spoke_vpcs
  source                = "./modules/spoke_vpc"
  identifier            = var.identifier
  vpc_name              = each.key
  cidr_block            = each.value.cidr_block
  number_azs            = each.value.number_azs
  azs_available         = data.aws_availability_zones.available.names
  enable_logging        = each.value.enable_logging
  tgw_id                = aws_ec2_transit_gateway.tgw.id
  vpc_flowlog_role      = each.value.enable_logging ? var.log_variables.vpc_flowlog_role : ""
  kms_key               = each.value.enable_logging ? var.log_variables.kms_key : ""
  endpoints_vpc_created = var.endpoints_vpc.create_vpc
}

# SSM VPC ENDPOINTS
# VPC endpoints - If Endpoints VPC is created, VPC endpoints are created there. If not, VPC endpoints are created in all the Spoke VPCs created
module "centralized_endpoints" {
  count          = var.endpoints_vpc.create_vpc ? 1 : 0
  source         = "./modules/vpc_endpoints"
  identifier     = var.identifier
  sg_info        = local.security_groups.vpc_endpoints
  endpoints_info = local.vpc_endpoints
  vpc_id         = module.endpoints_vpc[0].vpc_id
  vpc_subnets    = module.endpoints_vpc[0].endpoints_subnets
}

module "decentralized_endpoints" {
  for_each = {
    for key, value in module.spoke_vpcs : key => value
    if !var.endpoints_vpc.create_vpc
  }
  source         = "./modules/vpc_endpoints"
  identifier     = var.identifier
  sg_info        = local.security_groups.vpc_endpoints
  endpoints_info = local.vpc_endpoints
  vpc_id         = each.value.vpc_id
  vpc_subnets    = each.value.endpoints_subnets
}

# PRIVATE HOSTED ZONES
# If endpoints are centralized, Spoke VPCs, Endpoints/DNS VPC need to have PHZs associated
module "phz" {
  count                  = var.endpoints_vpc.create_vpc ? 1 : 0
  source                 = "./modules/phz"
  spoke_vpcs             = { for key, value in module.spoke_vpcs : key => value.vpc_id }
  central_vpc            = var.dns_vpc.create_vpc ? module.dns_vpc[0].vpc_id : module.endpoints_vpc[0].vpc_id
  endpoint_info          = module.centralized_endpoints[0].vpc_endpoint_dns
  endpoint_service_names = local.vpc_endpoints
}
