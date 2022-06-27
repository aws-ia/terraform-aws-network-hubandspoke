# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/central_inspection/modules/vpc_endpoints/outputs.tf ---

output "endpoints" {
  value       = { for k, v in aws_vpc_endpoint.endpoint : k => v.id }
  description = "VPC Endpoints DNS information."
}