# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_shared_services/locals.tf ---

locals {
  security_groups = {
    instance = {
      name        = "instance_security_group"
      description = "Instance SG (Allowing ICMP and HTTP/HTTPS access)"
      ingress = {
        icmp = {
          description = "Allowing ICMP traffic"
          from        = -1
          to          = -1
          protocol    = "icmp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
      egress = {
        any = {
          description = "Any traffic"
          from        = 0
          to          = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }

    endpoints = {
      name        = "endpoints_sg"
      description = "Security Group for SSM connection"
      ingress = {
        https = {
          description = "Allowing HTTPS"
          from        = 443
          to          = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
      egress = {
        any = {
          description = "Any traffic"
          from        = 0
          to          = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  endpoint_service_names = {
    ssm = {
      name           = "com.amazonaws.${var.aws_region}.ssm"
      type           = "Interface"
      private_dns    = false
      phz_name       = "ssm.${var.aws_region}.amazonaws.com"
    }
    ssmmessages = {
      name           = "com.amazonaws.${var.aws_region}.ssmmessages"
      type           = "Interface"
      private_dns    = false
      phz_name       = "ssmmessages.${var.aws_region}.amazonaws.com"
    }
    ec2messages = {
      name           = "com.amazonaws.${var.aws_region}.ec2messages"
      type           = "Interface"
      private_dns    = false
      phz_name       = "ec2messages.${var.aws_region}.amazonaws.com"
    }
  }
}