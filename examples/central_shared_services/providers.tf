# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_shared_services/providers.tf ---

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.73.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 0.15.0"
    }
  }

  required_version = ">= 0.15.0"
  experiments      = [module_variable_optional_attrs]
}

# AWS Providers configuration - AWS Region indicated in root/variables.tf
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

provider "awscc" {
  region = var.aws_region
}