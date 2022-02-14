# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/vpc_endpoints/variables.tf ---

variable "identifier" {
  type        = string
  description = "Module identifier."
}

variable "sg_info" {
  type        = any
  description = "Security Groups Information."
}

variable "endpoints_info" {
  type        = map(any)
  description = "VPC Endpoints Information."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "vpc_subnets" {
  type        = list(any)
  description = "List of subnets - to place the VPC endpoint."
}