# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/endpoints/modules/compute/outputs.tf ---

output "ec2_instances" {
  value       = aws_instance.ec2_instance.*.id
  description = "EC2 instances created."
}