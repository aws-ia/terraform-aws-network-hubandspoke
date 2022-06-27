# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/variables.tf ---

variable "aws_region" {
  type        = string
  description = "AWS Region - to build the Hub and Spoke."
  default     = "eu-west-1"
}

variable "identifier" {
  type        = string
  description = "Project identifier."
  default     = "central-inspection"
}

variable "vpcs" {
  type        = map(any)
  description = "Spoke VPCs to create."
  default = {
    "spoke-vpc-1" = {
      cidr_block      = "10.0.0.0/24"
      private_subnets = ["10.0.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]
      tgw_subnets     = ["10.0.0.192/28", "10.0.0.208/28", "10.0.0.224/28"]
      number_azs      = 2
      instance_type   = "t2.micro"
    }
    "spoke-vpc-2" = {
      cidr_block      = "10.0.1.0/24"
      private_subnets = ["10.0.1.0/26", "10.0.1.64/26", "10.0.1.128/26"]
      tgw_subnets     = ["10.0.1.192/28", "10.0.1.208/28", "10.0.1.224/28"]
      number_azs      = 2
      instance_type   = "t2.micro"
    }
  }
}