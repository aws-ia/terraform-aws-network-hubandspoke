# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/inspection/modules/compute/variables.tf ---

variable "identifier" {
  type        = string
  description = "Identifier."
}

variable "vpc_name" {
  type        = string
  description = "Name of the Spoke VPC to place the EC2 instances."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID of the Spoke VPC to place the EC2 instances."
}

variable "ami" {
  type        = string
  description = "AMI to use in the EC2 instances."
}

variable "instance_type" {
  type        = string
  description = "Instance type to use in the EC2 instances."
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets to place the EC2 instances."
}

variable "role_id" {
  type        = string
  description = "IAM Role to use in the EC2 instances."
}

variable "sg_information" {
  type        = any
  description = "Information about the Security Groups to create in each Spoke VPC."
}