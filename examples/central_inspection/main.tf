# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/main.tf ---

# We create the transit gateway outside of the Hub and Spoke module
resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "Transit_Gateway-${var.identifier}"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "transit_gateway-${var.identifier}"
  }
}

# Hub and Spoke module - we only centralize the Inspection
module "hub-and-spoke" {
  source = "../.."

  aws_region = var.aws_region
  identifier = var.identifier

  transit_gateway = {
    id = aws_ec2_transit_gateway.tgw.id
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
    }
  }
}