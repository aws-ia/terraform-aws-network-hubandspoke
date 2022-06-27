# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/aws_network_firewall/route_public_to_firewall/main.tf ---

resource "aws_route" "public_to_firewall_endpoint" {
  count = length(var.routes)

  route_table_id         = var.route_table_id
  destination_cidr_block = var.routes[count.index]
  vpc_endpoint_id        = var.vpc_endpoint_id
}