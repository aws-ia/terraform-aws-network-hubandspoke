# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_egress_ingress/variables.tf ---

variable "aws_region" {
  type        = string
  description = "AWS Region - to build the Hub and Spoke."
  default     = "eu-west-1"
}

variable "identifier" {
  type        = string
  description = "Project identifier."
  default     = "central-egress-ingress"
}

variable "spoke_vpcs" {
  type        = any
  description = "Spoke VPCs definition."
  default = {

    "prod1" = {
      type                     = "production"
      cidr_block               = "10.0.0.0/24"
      private_subnet_netmask   = 28
      tgw_subnet_netmask       = 28
      endpoints_subnet_netmask = 28
      az_count                 = 2
      instance_type            = "t2.micro"
    }
    "prod2" = {
      type                     = "production"
      cidr_block               = "10.0.1.0/24"
      private_subnet_netmask   = 28
      tgw_subnet_netmask       = 28
      endpoints_subnet_netmask = 28
      az_count                 = 2
      instance_type            = "t2.micro"
    }
  }
}