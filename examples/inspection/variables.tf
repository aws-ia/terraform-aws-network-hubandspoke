# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/inspection/variables.tf ---

# Module identifier
variable "identifier" {
  type        = string
  description = "Project identifier"

  default = "hub-spoke-inspection"
}

# AWS REGION
variable "aws_region" {
  type        = string
  description = "AWS Region to create the environment."

  default = "eu-west-1"
}

# CIDR blocks to use
variable "cidr_blocks" {
  type        = any
  description = "CIDR blocks to use in the different VPCs to create"

  default = {
    inspection_vpc = "10.10.0.0/16"
    spoke_vpcs = {
      spoke_1 = "10.0.0.0/16"
    }
  }
}

# Number of AZs we are configuring in all the VPCs created
variable "number_azs" {
  type        = number
  description = "Number of AZs - to indicate in all the VPCs created"

  default = 2
}

# EC2 instance type
variable "instance_type" {
  type        = string
  description = "Instance type to use in the EC2 instances."

  default = "t2.micro"
}