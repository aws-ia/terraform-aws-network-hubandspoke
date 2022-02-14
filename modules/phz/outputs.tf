# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/phz/outputs.tf ---

output "phzs" {
  value       = { for key, value in aws_route53_zone.private_hosted_zone : key => value.arn }
  description = "Private Hosted Zones created."
}