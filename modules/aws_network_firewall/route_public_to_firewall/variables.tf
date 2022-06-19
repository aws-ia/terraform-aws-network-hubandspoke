# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/aws_network_firewall/route_public_to_firewall/variables.tf ---

variable "route_table_id" {
  description = "VPC public route table ID."
  type        = string
}

variable "routes" {
  description = "List of destination routes to forward via the TGW."
  type        = list(string)
}

variable "vpc_endpoint_id" {
  description = "Network Firewall endpoint ID."
  type        = string
}

