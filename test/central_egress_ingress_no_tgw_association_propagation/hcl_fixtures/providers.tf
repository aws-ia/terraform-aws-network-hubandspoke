terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.73.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      "owner" = "Terratest"
    }
  }
}
