# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/locals.tf ---

locals {
  security_groups = {
    vpc_endpoints = {
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
          protocol    = -1
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  vpc_endpoints = {
    ssm = {
      name        = "com.amazonaws.${var.aws_region}.ssm"
      type        = "Interface"
      private_dns = !var.endpoints_vpc.create_vpc
      phz_name    = "ssm.${var.aws_region}.amazonaws.com"
    }
    ssmmessages = {
      name        = "com.amazonaws.${var.aws_region}.ssmmessages"
      type        = "Interface"
      private_dns = !var.endpoints_vpc.create_vpc
      phz_name    = "ssmmessages.${var.aws_region}.amazonaws.com"
    }
    ec2messages = {
      name        = "com.amazonaws.${var.aws_region}.ec2messages"
      type        = "Interface"
      private_dns = !var.endpoints_vpc.create_vpc
      phz_name    = "ec2messages.${var.aws_region}.amazonaws.com"
    }
  }

  # # VALIDATION 1 - Inspection VPC with Egress & Egress VPC are not allowed at the same time
  # validate_double_egress_point_cnd = var.inspection_vpc.create_vpc && var.inspection_vpc.enable_egress && var.egress_vpc.create_vpc
  # validate_double_egress_point_msg = "Please enable only one egress point: either within the Inspection VPC or in a central Egress VPC."
  # validate_double_egress_point_chk = regex("^${local.validate_double_egress_point_msg}$", (!local.validate_double_egress_point_cnd ? local.validate_double_egress_point_msg : ""))

  # # VALIDATION 2 - Endpoints VPC with DNS subnets & DNS VPC are not allowed at the same time 
  # validate_double_dns_vpc_cnd = var.endpoints_vpc.create_vpc && var.endpoints_vpc.enable_dns && var.dns_vpc.create_vpc
  # validate_double_dns_vpc_msg = "Please enable only one VPC for DNS forwarders: either within the Endpoints VPC or in a central DNS VPC."
  # validate_double_dns_vpc_chk = regex("^${local.validate_double_dns_vpc_msg}$", (!local.validate_double_dns_vpc_cnd ? local.validate_double_dns_vpc_msg : ""))

  # # VALIDATION 3 - Inspection VPC has logging enabled, but no IAM role or KMS Key has been added
  # validate_logging_inspection_cnd = (var.inspection_vpc.create_vpc && var.inspection_vpc.enable_logging) && (var.log_variables.vpc_flowlog_role == null || var.log_variables.kms_key == null)
  # validate_logging_inspection_msg = "You have enabled logging in the Inspection VPC, but you did not add the IAM role needed for VPC Flow logs, or the KMS Key to encrypt the logs. It is compulsory to add them to enable logging."
  # validate_logging_inspection_chk = regex("^${local.validate_logging_inspection_msg}$", (!local.validate_logging_inspection_cnd ? local.validate_logging_inspection_msg : ""))

  # # VALIDATION 4 - Egress VPC has logging enabled, but no IAM role or KMS Key has been added
  # validate_logging_egress_cnd = (var.egress_vpc.create_vpc && var.egress_vpc.enable_logging) && (var.log_variables.vpc_flowlog_role == null || var.log_variables.kms_key == null)
  # validate_logging_egress_msg = "You have enabled logging in the Egress VPC, but you did not add the IAM role needed for VPC Flow logs, or the KMS Key to encrypt the logs. It is compulsory to add them to enable logging."
  # validate_logging_egress_chk = regex("^${local.validate_logging_egress_msg}$", (!local.validate_logging_egress_cnd ? local.validate_logging_egress_msg : ""))

  # # VALIDATION 5 - Ingress VPC has logging enabled, but no IAM role or KMS Key has been added
  # validate_logging_ingress_cnd = (var.ingress_vpc.create_vpc && var.ingress_vpc.enable_logging) && (var.log_variables.vpc_flowlog_role == null || var.log_variables.kms_key == null)
  # validate_logging_ingress_msg = "You have enabled logging in the Ingress VPC, but you did not add the IAM role needed for VPC Flow logs, or the KMS Key to encrypt the logs. It is compulsory to add them to enable logging."
  # validate_logging_ingress_chk = regex("^${local.validate_logging_ingress_msg}$", (!local.validate_logging_ingress_cnd ? local.validate_logging_ingress_msg : ""))

  # # VALIDATION 6 - Endpoints VPC has logging enabled, but no IAM role or KMS Key has been added
  # validate_logging_endpoints_cnd = (var.endpoints_vpc.create_vpc && var.endpoints_vpc.enable_logging) && (var.log_variables.vpc_flowlog_role == null || var.log_variables.kms_key == null)
  # validate_logging_endpoints_msg = "You have enabled logging in the Endpoints VPC, but you did not add the IAM role needed for VPC Flow logs, or the KMS Key to encrypt the logs. It is compulsory to add them to enable logging."
  # validate_logging_endpoints_chk = regex("^${local.validate_logging_endpoints_msg}$", (!local.validate_logging_endpoints_cnd ? local.validate_logging_endpoints_msg : ""))

  # # VALIDATION 7 - DNS VPC has logging enabled, but no IAM role or KMS Key has been added
  # validate_logging_dns_cnd = (var.dns_vpc.create_vpc && var.dns_vpc.enable_logging) && (var.log_variables.vpc_flowlog_role == null || var.log_variables.kms_key == null)
  # validate_logging_dns_msg = "You have enabled logging in the DNS VPC, but you did not add the IAM role needed for VPC Flow logs, or the KMS Key to encrypt the logs. It is compulsory to add them to enable logging."
  # validate_logging_dns_chk = regex("^${local.validate_logging_dns_msg}$", (!local.validate_logging_dns_cnd ? local.validate_logging_dns_msg : ""))
}