# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/aws_network_firewall/variables.tf ---

variable "identifier" {
  description = "Project identifier."
  type        = string
}

variable "firewall_configuration" {
  description = "AWS Network Firewall configuration variables."
  type        = map(any)
}

variable "inspection_vpc" {
  description = "Information about the Inspection VPC created."
  type        = any
}

variable "tgw_id" {
  description = "Transit Gateway ID."
  type        = string
}

variable "number_azs" {
  description = "Number of AZs used in the Inspection VPC."
  type        = number
}

variable "route_to_tgw" {
  description = "CIDR block destination to forward traffic to the TGW."
  type        = list(string)
}

variable "internet_access" {
  description = "Indicates if the Inspection VPC was created with Internet access."
  type        = bool
}