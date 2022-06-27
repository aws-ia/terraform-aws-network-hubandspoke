# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/aws_network_firewall/main.tf ---

# AWS Network Firewall Resource
resource "aws_networkfirewall_firewall" "anfw" {
  name                = "${var.firewall_configuration.name}-${var.identifier}"
  firewall_policy_arn = var.firewall_configuration.firewall_policy
  vpc_id              = var.inspection_vpc.vpc_attributes.id

  firewall_policy_change_protection = try(var.firewall_configuration.firewall_policy_change_protection, false)
  subnet_change_protection          = try(var.firewall_configuration.subnet_change_protection, false)

  dynamic "subnet_mapping" {
    for_each = values({ for k, v in var.inspection_vpc.private_subnet_attributes_by_az : k => v.id })

    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = try(var.firewall_configuration.tags, {})
}

# Route from the TGW subnet to the firewall endpoint
resource "aws_route" "tgw_to_firewall_endpoint" {
  count = var.number_azs

  route_table_id         = var.inspection_vpc.route_table_by_subnet_type.transit_gateway[local.availability_zones[count.index]].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = { for i in aws_networkfirewall_firewall.anfw.firewall_status[0].sync_states : i.availability_zone => i.attachment[0].endpoint_id }[local.availability_zones[count.index]]
}

# Route from the Public Subnet (if created) to the Segment CIDR block via the firewall endpoint
module "route_public_to_firewall" {
  count  = var.internet_access ? var.number_azs : 0
  source = "./route_public_to_firewall"

  route_table_id  = var.inspection_vpc.route_table_by_subnet_type.public[local.availability_zones[count.index]].id
  routes          = var.route_to_tgw
  vpc_endpoint_id = { for i in aws_networkfirewall_firewall.anfw.firewall_status[0].sync_states : i.availability_zone => i.attachment[0].endpoint_id }[local.availability_zones[count.index]]
}

# Logging configuration (PLACEHOLDER)