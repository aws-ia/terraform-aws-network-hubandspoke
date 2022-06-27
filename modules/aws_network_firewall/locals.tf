# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/aws_network_firewall/locals.tf ---

locals {
  availability_zones = keys({ for k, v in var.inspection_vpc.private_subnet_attributes_by_az : k => v })
}