# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_shared_services/main.tf ---

# AWS Transit Gateway
resource "aws_ec2_transit_gateway" "tgw" {

  description                     = "Transit_Gateway-${var.identifier}"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  amazon_side_asn                 = 64515

  tags = {
    Name = "tgw-${var.identifier}"
  }
}

# Hub and Spoke module - we only centralize the Shared Services and Hybrid DNS VPCs
module "hub-and-spoke" {
  source = "../.."

  identifier         = var.identifier
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  network_definition = {
    type  = "CIDR"
    value = "10.0.0.0/14"
  }

  central_vpcs = {
    shared_services = {
      name       = "shared-services-vpc"
      cidr_block = "10.10.0.0/24"
      az_count   = 2

      subnets = {
        endpoints       = { netmask = 28 }
        transit_gateway = { netmask = 28 }
      }
    }
  }

  spoke_vpcs = {
    production = {
      for k, v in module.spoke_vpcs : k => {
        vpc_id                        = v.vpc_attributes.id
        transit_gateway_attachment_id = v.transit_gateway_attachment_id
      }
      if var.spoke_vpcs[k].type == "production"
    }
    development = {
      for k, v in module.spoke_vpcs : k => {
        vpc_id                        = v.vpc_attributes.id
        transit_gateway_attachment_id = v.transit_gateway_attachment_id
      }
      if var.spoke_vpcs[k].type == "development"
    }
    testing = {
      for k, v in module.spoke_vpcs : k => {
        vpc_id                        = v.vpc_attributes.id
        transit_gateway_attachment_id = v.transit_gateway_attachment_id
      }
      if var.spoke_vpcs[k].type == "testing"
    }
  }
}

# Spoke VPCs
module "spoke_vpcs" {
  for_each = var.spoke_vpcs

  source  = "aws-ia/vpc/aws"
  version = "= 3.0.0"

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.az_count

  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  transit_gateway_routes = {
    private = "0.0.0.0/0"
  }

  subnets = {
    private = {
      name_prefix = "private-subnet"
      netmask     = each.value.private_subnet_netmask
    }
    transit_gateway = {
      name_prefix                                     = "tgw-subnet"
      netmask                                         = each.value.tgw_subnet_netmask
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }
  }
}

# EC2 Instances (in each Spoke VPC)
module "compute" {
  for_each = module.spoke_vpcs
  source   = "./modules/compute"

  identifier               = var.identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "private" })
  number_azs               = var.spoke_vpcs[each.key].az_count
  instance_type            = var.spoke_vpcs[each.key].instance_type
  ec2_iam_instance_profile = module.iam.ec2_iam_instance_profile
  ec2_security_group       = local.security_groups.instance
}

# VPC Endpoints (in Shared Services VPC)
module "vpc_endpoints" {
  source = "./modules/vpc_endpoints"

  identifier               = var.identifier
  vpc_name                 = "shared_services"
  vpc_id                   = module.hub-and-spoke.central_vpcs["shared_services"].vpc_attributes.id
  vpc_subnets              = values({ for k, v in module.hub-and-spoke.central_vpcs["shared_services"].private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" })
  endpoints_security_group = local.security_groups.endpoints
  endpoints_service_names  = local.endpoint_service_names
}

# Private Hosted Zones
module "phz" {
  source = "./modules/phz"

  vpc_ids                = { for k, v in module.spoke_vpcs : k => v.vpc_attributes.id }
  endpoint_dns           = module.vpc_endpoints.endpoint_dns
  endpoint_service_names = local.endpoint_service_names
}

# IAM Resources
module "iam" {
  source = "./modules/iam"

  identifier = var.identifier
}