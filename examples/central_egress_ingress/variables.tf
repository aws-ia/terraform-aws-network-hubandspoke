# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/variables.tf ---

variable "aws_region" {
  type        = string
  description = "AWS Region - to build the Hub and Spoke."
  default     = "eu-west-1"
}

variable "identifier" {
  type        = string
  description = "Project identifier."
  default     = "central-egress-ingress"
}