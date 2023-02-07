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

variable "spoke_vpcs" {
  type        = map(any)
  description = "Spoke VPCs."
  default = {
    "prod-vpc" = {
      routing_domain = "prod"
      cidr_block     = "10.0.0.0/24"
      number_azs     = 2
    }
    "nonprod-vpc" = {
      routing_domain = "nonprod"
      cidr_block     = "10.0.1.0/24"
      number_azs     = 2
    }
  }
}