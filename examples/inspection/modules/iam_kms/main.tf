# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/inspection/modules/iam_kms/main.tf ---

# DATA SOURCES 
# AWS CALLER IDENTITY - Used to get the Account ID
data "aws_caller_identity" "current" {}

# AWS Region
data "aws_region" "current" {}

# EC2 INSTANCE IAM ROLE - SSM access
# IAM instance profile
resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = "ec2_ssm_instance_profile_${var.identifier}"
  role = aws_iam_role.role_ec2_ssm.id
}

# IAM role
data "aws_iam_policy_document" "policy_document" {
  statement {
    sid     = "1"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

  }
}

resource "aws_iam_role" "role_ec2_ssm" {
  name               = "ec2_ssm_role_${var.identifier}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.policy_document.json
}

# Policy Attachments to Role
resource "aws_iam_policy_attachment" "ssm_iam_role_polcy_attachment" {
  name       = "ssm_iam_role_polcy_attachment_${var.identifier}"
  roles      = [aws_iam_role.role_ec2_ssm.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "ssm_iam_service_role_attachment" {
  name       = "ssm_iam_service_role_attachment_${var.identifier}"
  roles      = [aws_iam_role.role_ec2_ssm.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# VPC FLOW LOGS - ROLE AND POLICY
# IAM Role
data "aws_iam_policy_document" "policy_role_document" {
  statement {
    sid     = "1"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_flowlogs_role" {
  name               = "vpc-flowlog-role-${var.identifier}"
  assume_role_policy = data.aws_iam_policy_document.policy_role_document.json
}

# IAM Role Policy
data "aws_iam_policy_document" "policy_rolepolicy_document" {
  statement {
    sid = "2"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroup",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }
}

resource "aws_iam_role_policy" "vpc_flowlogs_role_policy" {
  name   = "vpc-flowlog-role-policy-${var.identifier}"
  role   = aws_iam_role.vpc_flowlogs_role.id
  policy = data.aws_iam_policy_document.policy_rolepolicy_document.json
}

# KMS
# KMS Key
resource "aws_kms_key" "log_key" {
  description             = "KMS Logs Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.policy_kms_logs_document.json

  tags = {
    Name = "kms-key-${var.identifier}"
  }
}

# KMS Policy - it allows the use of the Key by the CloudWatch log groups created in this sample
data "aws_iam_policy_document" "policy_kms_logs_document" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "Enable KMS to be used by CloudWatch Logs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}