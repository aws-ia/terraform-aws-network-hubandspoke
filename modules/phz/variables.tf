# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/phz/variables.tf ---

variable "spoke_vpcs" {
  type        = map(string)
  description = "List of Spoke VPC IDs."
}

variable "central_vpc" {
  type        = string
  description = "Central (Endpoint or DNS) ID."
}

variable "endpoint_info" {
  type        = any
  description = "VPC endpoints' DNS information."
}

variable "endpoint_service_names" {
  type        = map(any)
  description = "VPC endpoints information (from locals.tf)"
}
