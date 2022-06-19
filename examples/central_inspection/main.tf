# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/main.tf ---

# Hub and Spoke module - we only centralize the Traffic Inspection
module "hub-and-spoke" {
  source = "../.."

  identifier = var.identifier
  transit_gateway = {
    configuration = {
      name            = "transit_gateway"
      amazon_side_asn = 65520
    }
  }

  central_vpcs = {
    inspection = {
      name       = "inspection-vpc"
      cidr_block = "10.10.0.0/16"
      az_count   = 2

      subnets = {
        public = {
          netmask = 24
        }
        inspection = {
          netmask = 24
        }
        transit_gateway = {
          netmask = 28
        }
      }

      aws_network_firewall = {
        name            = "anfw"
        firewall_policy = aws_networkfirewall_firewall_policy.anfw_policy.arn
      }
    }
  }

  spoke_vpcs = {
    number_spokes   = length(var.vpcs)
    cidrs_list      = ["10.0.0.0/8"]
    vpc_attachments = values({ for k, v in module.spoke_vpcs : k => v.transit_gateway_attachment_id })
  }
}

# Spoke VPCs to create (from var.vpcs)
module "spoke_vpcs" {
  for_each = var.vpcs
  source   = "aws-ia/vpc/aws"
  version  = "= 1.4.0"

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  subnets = {
    private = {
      name_prefix              = "private"
      cidrs                    = slice(each.value.private_subnets, 0, each.value.number_azs)
      route_to_nat             = false
      route_to_transit_gateway = ["0.0.0.0/0"]
    }
    transit_gateway = {
      name_prefix                                     = "tgw"
      cidrs                                           = slice(each.value.tgw_subnets, 0, each.value.number_azs)
      transit_gateway_id                              = module.hub-and-spoke.transit_gateway.id
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }
  }

  vpc_flow_logs = {
    iam_role_arn = module.iam_kms.vpc_flowlog_role
    kms_key_arn  = module.iam_kms.kms_arn

    log_destination_type = "cloud-watch-logs"
    retention_in_days    = 7
  }
}

# EC2 Instances (1 instance in each private subnet per Spoke VPC created)
module "compute" {
  for_each = module.spoke_vpcs
  source   = "./modules/compute"

  identifier               = var.identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : k => v.id })
  number_azs               = var.vpcs[each.key].number_azs
  instance_type            = var.vpcs[each.key].instance_type
  ec2_iam_instance_profile = module.iam_kms.ec2_iam_instance_profile
  ec2_security_group       = local.security_groups.instance
}

# VPC Endpoints - to connect to the instances using Systems Manager (Endpoint definition in locals.tf)
module "vpc_endpoints" {
  for_each = module.spoke_vpcs
  source   = "./modules/vpc_endpoints"

  identifier               = var.identifier
  vpc_name                 = each.key
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : k => v.id })
  endpoints_security_group = local.security_groups.endpoints
  endpoints_service_names  = local.endpoint_service_names
}

# IAM Roles and KMS Keys
module "iam_kms" {
  source = "./modules/iam_kms"

  identifier = var.identifier
  aws_region = var.aws_region
}


