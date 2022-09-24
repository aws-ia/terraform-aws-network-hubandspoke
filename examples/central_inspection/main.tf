# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/main.tf ---

# Hub and Spoke module - we only centralize the Inspection
module "hub-and-spoke" {
  source = "../.."

  identifier = var.identifier
  transit_gateway_attributes = {
    name            = "tgw-${var.identifier}"
    description     = "Transit_Gateway-${var.identifier}"
    amazon_side_asn = 65000
  }

  network_definition = {
    type  = "PREFIX_LIST"
    value = aws_ec2_managed_prefix_list.network_prefix_list.id
  }

  central_vpcs = {
    inspection = {
      name            = "inspection-vpc"
      cidr_block      = "10.10.0.0/24"
      az_count        = 2
      inspection_flow = "north-south"

      aws_network_firewall = {
        name       = "anfw-${var.identifier}"
        policy_arn = aws_networkfirewall_firewall_policy.anfw_policy.arn
      }

      subnets = {
        public          = { netmask = 28 }
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
    nonproduction = {
      for k, v in module.spoke_vpcs : k => {
        vpc_id                        = v.vpc_attributes.id
        transit_gateway_attachment_id = v.transit_gateway_attachment_id
      }
      if var.spoke_vpcs[k].type == "nonproduction"
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

  transit_gateway_id = module.hub-and-spoke.transit_gateway.id
  transit_gateway_routes = {
    private = "0.0.0.0/0"
  }

  subnets = {
    private = {
      name_prefix = "private-subnet"
      netmask     = each.value.private_subnet_netmask
    }
    endpoints = {
      name_prefix = "endpoints-subnet"
      netmask     = each.value.endpoints_subnet_netmask
    }
    transit_gateway = {
      name_prefix                                     = "tgw-subnet"
      netmask                                         = each.value.tgw_subnet_netmask
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }
  }
}

# Managed prefix list (to pass to the Hub and Spoke module)
resource "aws_ec2_managed_prefix_list" "network_prefix_list" {
  name           = "Network's Prefix List"
  address_family = "IPv4"
  max_entries    = length(keys(var.spoke_vpcs))
}

resource "aws_ec2_managed_prefix_list_entry" "entry" {
  for_each = var.spoke_vpcs

  cidr           = each.value.cidr_block
  description    = "${each.value.type}-${each.key}"
  prefix_list_id = aws_ec2_managed_prefix_list.network_prefix_list.id
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

# VPC Endpoints (in each Spoke VPC)
module "vpc_endpoints" {
  for_each = module.spoke_vpcs
  source   = "./modules/vpc_endpoints"

  identifier               = var.identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" })
  endpoints_security_group = local.security_groups.endpoints
  endpoints_service_names  = local.endpoint_service_names
}

# IAM Resources
module "iam" {
  source = "./modules/iam"

  identifier = var.identifier
}

