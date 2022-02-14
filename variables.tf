# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/variables.tf ---

# Module identifier
variable "identifier" {
  type        = string
  description = "Module identifier"
}

# AWS REGION
variable "aws_region" {
  type        = string
  description = "AWS Region to create the environment."
}

# VPC FLOW LOG VARIABLES 
variable "log_variables" {
  description = "Variables needed if logging is enabled."

  type = object({
    vpc_flowlog_role = optional(string)
    kms_key          = optional(string)
  })

  default = {
    vpc_flowlog_role = null
    kms_key          = null
  }
}

# Variable to create an Inspection VPC
variable "inspection_vpc" {
  description = "Variables to create an Inspection VPC."

  type = object({
    create_vpc     = bool
    cidr_block     = optional(string)
    number_azs     = optional(number)
    enable_logging = optional(bool)
    enable_egress  = optional(bool)
  })

  default = {
    create_vpc     = false
    cidr_block     = null
    number_azs     = null
    enable_logging = false
    enable_egress  = false
  }
}

# Variable to create an Egress VPC
variable "egress_vpc" {
  description = "Variables to create an Engress VPC."

  type = object({
    create_vpc     = bool
    cidr_block     = optional(string)
    number_azs     = optional(number)
    enable_logging = optional(bool)
  })

  default = {
    create_vpc     = false
    cidr_block     = null
    number_azs     = null
    enable_logging = false
  }
}

# Variable to create an Ingress VPC
variable "ingress_vpc" {
  description = "Variables to create an Ingress VPC."

  type = object({
    create_vpc     = bool
    cidr_block     = optional(string)
    number_azs     = optional(number)
    enable_logging = optional(bool)
  })

  default = {
    create_vpc     = false
    cidr_block     = null
    number_azs     = null
    enable_logging = false
  }
}

# Variable to create a Central Endpoints VPC
variable "endpoints_vpc" {
  description = "Variables to create a Central Endpoints VPC."

  type = object({
    create_vpc     = bool
    cidr_block     = optional(string)
    number_azs     = optional(number)
    enable_logging = optional(bool)
    enable_dns     = optional(bool)
  })

  default = {
    create_vpc     = false
    cidr_block     = null
    number_azs     = null
    enable_logging = false
    enable_dns     = false
  }
}

# Variable to create a Central DNS VPC
variable "dns_vpc" {
  description = "Variables to create a Central DNS VPC."

  type = object({
    create_vpc     = bool
    cidr_block     = optional(string)
    number_azs     = optional(number)
    enable_logging = optional(bool)
  })

  default = {
    create_vpc     = false
    cidr_block     = null
    number_azs     = null
    enable_logging = false
  }
}

# Variable to create Spoke VPCs
variable "spoke_vpcs" {
  description = "Variables to create Spoke VPCs."

  type = map(object({
    cidr_block     = optional(string)
    number_azs     = optional(number)
    enable_logging = optional(bool)
  }))

  default = {}
}