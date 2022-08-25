# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/spoke_vpcs/variables.tf ---

variable "identifier" {
    type = string
    description = "Project identifier."
}

variable "transit_gateway_id" {
    type = string
    description = "AWS Transit Gateway ID."
}

variable "segment_name" {
    type = string
    description = "Segment name."
}

variable "segment_information" {
    type = any
    description = "Information about the segment to create (CIDR block/prefix list, and Spoke VPCs information)."
}