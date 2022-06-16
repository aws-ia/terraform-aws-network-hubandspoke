# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/main.tf ---

# Hub and Spoke module - we only centralize the Egress and Ingress traffic
module "hub-and-spoke" {
  source = "../.."

  aws_region = var.aws_region
  identifier = var.identifier

  transit_gateway = {
    name = "tgw-${var.identifier}"
  }

  central_vpcs = {
    shared_services = {
      name       = "shared-services-vpc"
      cidr_block = "10.10.0.0/16"
      az_count   = 2

      subnets = {
        endpoints = {
          netmask = 24
        }
        transit_gateway = {
          netmask = 28
        }
      }
    }

    hybrid_dns = {
      name       = "hybrid-dns-vpc"
      cidr_block = "10.20.0.0/16"
      az_count   = 2

      subnets = {
        endpoints = {
          netmask = 24
        }
        transit_gateway = {
          netmask = 28
        }
      }
    }
  }
}