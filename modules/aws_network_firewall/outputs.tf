# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/aws_network_firewall/outputs.tf ---

output "network_firewall" {
  description = "AWS Network Firewall."
  value       = aws_networkfirewall_firewall.anfw
}