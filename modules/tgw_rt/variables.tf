# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/tgw_rt/variables.tf ---

variable "identifier" {
  type        = string
  description = "Module identifier."
}

variable "inspection_vpc" {
  type        = bool
  description = "Value indicating if the Inspection VPC was created."
}

variable "egress_vpc" {
  type        = bool
  description = "Value indicating if the Egress VPC was created."
}

variable "ingress_vpc" {
  type        = bool
  description = "Value indicating if the Ingress VPC was created."
}

variable "endpoints_vpc" {
  type        = bool
  description = "Value indicating if the Endpoints VPC was created."
}

variable "dns_vpc" {
  type        = bool
  description = "Value indicating if the DNS VPC was created."
}

variable "tgw_id" {
  type        = string
  description = "Transit Gateway ID."
}

variable "inspection_tgw_attachment" {
  type        = string
  description = "Inspection VPC - TGW Attachment."
}

variable "egress_tgw_attachment" {
  type        = string
  description = "Egress VPC - TGW Attachment."
}

variable "ingress_tgw_attachment" {
  type        = string
  description = "Ingress VPC - TGW Attachment."
}

variable "endpoints_tgw_attachment" {
  type        = string
  description = "Endpoints VPC - TGW Attachment."
}

variable "dns_tgw_attachment" {
  type        = string
  description = "DNS VPC - TGW Attachment."
}

variable "spoke_tgw_attachments" {
  type        = map(string)
  description = "Spokes VPCs - TGW Attachment."
}

