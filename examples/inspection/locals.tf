# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/inspection/locals.tf ---

locals {
  # Security Groups (SGs) used by the EC2 instances ("instance")
  security_groups = {
    instance = {
      name        = "instance_sg"
      description = "Security Group used in the instances"
      ingress = {
        any = {
          description = "Any traffic"
          from        = 0
          to          = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
      egress = {
        icmp = {
          description = "ICMP traffic"
          from        = -1
          to          = -1
          protocol    = "icmp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        http = {
          description = "HTTP traffic"
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        https = {
          description = "HTTPS traffic"
          from        = 443
          to          = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
}