# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/providers.tf ---

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.73.0"
    }
  }

  required_version = "1.1.4"
  experiments      = [module_variable_optional_attrs]
}

# AWS Provider configuration - AWS Region indicated in root/variables.tf
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Module    = "hub-and-spoke-tgw"
      Terraform = "Managed"
      Region    = var.aws_region
    }
  }
}
