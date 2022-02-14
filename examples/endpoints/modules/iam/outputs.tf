# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/inspection/modules/iam_kms/outputs.tf ---

output "ec2_ssm_role" {
  value       = aws_iam_instance_profile.ec2_ssm_instance_profile.id
  description = "EC2 instance role to access SSM."
}