# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_shared_services/variables.tf ---

variable "aws_region" {
  type        = string
  description = "AWS Region - to build the Hub and Spoke."
  default     = "eu-west-1"
}

variable "identifier" {
  type        = string
  description = "Project identifier."
  default     = "central-shared-services"
}

variable "spoke_vpcs" {
  type        = any
  description = "Spoke VPCs definition."
  default = {

    "prod" = {
      type                     = "production"
      cidr_block               = "10.0.0.0/24"
      private_subnet_netmask   = 28
      tgw_subnet_netmask       = 28
      endpoints_subnet_netmask = 28
      az_count                 = 2
      instance_type            = "t2.micro"
    }
    "dev" = {
      type                     = "development"
      cidr_block               = "10.1.0.0/24"
      private_subnet_netmask   = 28
      tgw_subnet_netmask       = 28
      endpoints_subnet_netmask = 28
      az_count                 = 2
      instance_type            = "t2.micro"
    }
    "test" = {
      type                     = "testing"
      cidr_block               = "10.2.0.0/24"
      private_subnet_netmask   = 28
      tgw_subnet_netmask       = 28
      endpoints_subnet_netmask = 28
      az_count                 = 2
      instance_type            = "t2.micro"
    }
  }
}