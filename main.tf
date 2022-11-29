# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# ---------------- AWS TRANSIT GATEWAY ----------------
resource "aws_ec2_transit_gateway" "tgw" {
  count = local.create_tgw ? 1 : 0

  description                     = "Transit_Gateway-${var.identifier}"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  amazon_side_asn                 = try(var.transit_gateway_attributes.amazon_side_asn, 64512)
  auto_accept_shared_attachments  = try(var.transit_gateway_attributes.auto_accept_shared_attachments, "disable")
  dns_support                     = try(var.transit_gateway_attributes.dns_support, "enable")
  multicast_support               = try(var.transit_gateway_attributes.multicast_support, "disable")
  transit_gateway_cidr_blocks     = try(var.transit_gateway_attributes.transit_gateway_cidr_blocks, [])
  vpn_ecmp_support                = try(var.transit_gateway_attributes.vpn_ecmp_support, "enable")

  tags = merge({
    Name = try(var.transit_gateway_attributes.name, "tgw-${var.identifier}")
  }, try(var.transit_gateway_attributes.tags, {}))
}

# ---------------- CENTRAL VPCs ----------------
module "central_vpcs" {
  for_each = var.central_vpcs

  source  = "aws-ia/vpc/aws"
  version = "= 3.0.1"

  name               = try(each.value.name, each.key)
  vpc_id             = try(each.value.vpc_id, null)
  cidr_block         = try(each.value.cidr_block, null)
  vpc_secondary_cidr = try(each.value.vpc_secondary_cidr, false)
  az_count           = each.value.az_count

  vpc_enable_dns_hostnames = try(each.value.vpc_enable_dns_hostnames, true)
  vpc_enable_dns_support   = try(each.value.vpc_enable_dns_support, true)
  vpc_instance_tenancy     = try(each.value.vpc_instance_tenancy, "default")
  vpc_ipv4_ipam_pool_id    = try(each.value.vpc_ipv4_ipam_pool_id, null)
  vpc_ipv4_netmask_length  = try(each.value.vpc_ipv4_netmask_length, null)

  vpc_flow_logs = try(each.value.vpc_flow_logs, local.vpc_flow_logs_default)
  subnets       = merge(try(each.value.subnets, {}), local.subnet_config[each.key])

  transit_gateway_id     = local.transit_gateway_id
  transit_gateway_routes = local.transit_gateway_routes[each.key]

  tags = try(each.value.tags, {})
}

# -------- TRANSIT GATEWAY ROUTE TABLE AND ASSOCATIONS - CENTRAL VPCS --------
resource "aws_ec2_transit_gateway_route_table" "tgw_route_table" {
  for_each = module.central_vpcs

  transit_gateway_id = local.transit_gateway_id

  tags = {
    Name = "${each.key}-tgw-rt-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw_route_table_association" {
  for_each = module.central_vpcs

  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table[each.key].id
}

# --------- TRANSIT GATEWAY ROUTE TABLE, ASSOCATIONS, AND PROPAGATIONS (IF APPLIES) - SPOKE VPCS ---------
module "spoke_vpcs" {
  for_each = { for k, v in var.spoke_vpcs : k => v if local.spoke_vpc_information }
  source   = "./modules/spoke_vpcs"

  identifier         = var.identifier
  transit_gateway_id = local.transit_gateway_id

  segment_name        = each.key
  segment_information = each.value

  tgw_attachment_propagation = local.spoke_to_spoke_propagation
}

# ---------------------- TRANSIT GATEWAY STATIC ROUTES ----------------------
# Static Route (0.0.0.0/0) from Spoke VPCs to Inspection VPC if:
# 1/ The Inspection VPC is created and no Egress VPC is created or,
# 2/ Both Inspection VPC and Egress VPC are created, and the traffic inspection is "all" or "north-south".
resource "aws_ec2_transit_gateway_route" "spokes_to_inspection_default_route" {
  for_each = {
    for k, v in module.spoke_vpcs : k => v.transit_gateway_spoke_rt
    if local.spoke_to_inspection_default
  }

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.central_vpcs["inspection"].transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.id
}

# Static Route (0.0.0.0/0) from Spoke VPCs to Egress VPC if:
# 1/ The Egress VPC is created and no Inspection VPC is created or,
# 2/ Both Inspection VPC and Egress VPC are created, and the traffic inspection is "east-west".
resource "aws_ec2_transit_gateway_route" "spokes_to_egress_default_route" {
  for_each = {
    for k, v in module.spoke_vpcs : k => v.transit_gateway_spoke_rt
    if local.spoke_to_egress_default
  }

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.central_vpcs["egress"].transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.id
}

# Static Route (Network's CIDR) from Spoke VPCs to Inspection VPC if:
# 1/ Both Inspection VPC and Egress VPC are created, and the traffic inspection is "east-west".
resource "aws_ec2_transit_gateway_route" "spokes_to_inspection_network_route" {
  for_each = {
    for k, v in module.spoke_vpcs : k => v.transit_gateway_spoke_rt
    if local.spoke_to_inspection_network && !local.network_pl
  }

  destination_cidr_block         = var.network_definition.value
  transit_gateway_attachment_id  = module.central_vpcs["inspection"].transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.id
}

resource "aws_ec2_transit_gateway_prefix_list_reference" "spokes_to_inspection_network_prefix_list" {
  for_each = {
    for k, v in module.spoke_vpcs : k => v.transit_gateway_spoke_rt
    if local.spoke_to_inspection_network && local.network_pl
  }

  prefix_list_id                 = var.network_definition.value
  transit_gateway_attachment_id  = module.central_vpcs["inspection"].transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.id
}

# Static Route (0.0.0.0/0) from Inspection VPC to Egress VPC if:
# 1/ Both Inspection VPC and Egress VPC are created, and the traffic inspection is "all" or "north-south".
resource "aws_ec2_transit_gateway_route" "inspection_to_egress_default_route" {
  count = local.inspection_and_egress_routes ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.central_vpcs["egress"].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["inspection"].id
}

# Static Route (Network's CIDR) from Egress VPC to Inspection VPC if:
# 1/ Both Inspection VPC and Egress VPC are created, and the traffic inspection is "all" or "north-south".
resource "aws_ec2_transit_gateway_route" "egress_to_inspection_network_route" {
  count = local.inspection_and_egress_routes && !local.network_pl ? 1 : 0

  destination_cidr_block         = var.network_definition.value
  transit_gateway_attachment_id  = module.central_vpcs["inspection"].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["egress"].id
}

resource "aws_ec2_transit_gateway_prefix_list_reference" "egress_to_inspection_network_prefix_list" {
  count = local.inspection_and_egress_routes && local.network_pl ? 1 : 0

  prefix_list_id                 = var.network_definition.value
  transit_gateway_attachment_id  = module.central_vpcs["inspection"].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["egress"].id
}

# Static Route (Network's CIDR) from Ingress VPC to Inspection VPC if:
# 1/ Both Inspection VPC and Ingress VPC are created, and the traffic inspection is "all" or "north-south".
resource "aws_ec2_transit_gateway_route" "ingress_to_inspection_network_route" {
  count = local.ingress_to_inspection_network && !local.network_pl ? 1 : 0

  destination_cidr_block         = var.network_definition.value
  transit_gateway_attachment_id  = module.central_vpcs["inspection"].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["ingress"].id
}

resource "aws_ec2_transit_gateway_prefix_list_reference" "ingress_to_inspection_network_prefix_list" {
  count = local.ingress_to_inspection_network && local.network_pl ? 1 : 0

  prefix_list_id                 = var.network_definition.value
  transit_gateway_attachment_id  = module.central_vpcs["inspection"].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["ingress"].id
}

# -------------------- TRANSIT GATEWAY PROPAGATED ROUTES --------------------
# Spoke VPCs propagation to the Inspection RT - anytime this VPC is created
resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_to_inspection_propagation" {
  for_each = {
    for k, v in local.transit_gateway_attachment_ids : k => v
    if local.spoke_to_inspection_propagation
  }

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["inspection"].id
}

# Spoke VPCs propagation to the Egress RT if:
# 1/ The Egress VPC is created without Inspection VPC or,
# 2/ Both Egress and Inspection VPC are created, and the traffic inspeciton is "all" or "east-west"
resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_to_egress_propagation" {
  for_each = {
    for k, v in local.transit_gateway_attachment_ids : k => v
    if local.spoke_to_egress_propagation
  }

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["egress"].id
}

# Spoke VPCs propagation to the Ingress RT if:
# 1/ The Ingress VPC is created without Inspection VPC or,
# 2/ Both Egress and Inspection VPC are created, and the traffic inspeciton is "east-west"
resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_to_ingress_propagation" {
  for_each = {
    for k, v in local.transit_gateway_attachment_ids : k => v
    if local.spoke_to_ingress_propagation
  }

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["ingress"].id
}

# Spoke VPCs propagation to the Shared Services RT - anytime this VPC is created
resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_to_shared_services_propagation" {
  for_each = {
    for k, v in local.transit_gateway_attachment_ids : k => v
    if contains(keys(var.central_vpcs), "shared_services")
  }

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["shared_services"].id
}

# Spoke VPCs propagation to the Hybrid DNS RT - anytime this VPC is created
resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_to_hybrid_dns_propagation" {
  for_each = {
    for k, v in local.transit_gateway_attachment_ids : k => v
    if contains(keys(var.central_vpcs), "hybrid_dns")
  }

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["hybrid_dns"].id
}

# If Shared Services VPC is created, it propagates its CIDR to all the Segment TGW Route Tables
resource "aws_ec2_transit_gateway_route_table_propagation" "shared_services_to_spokes_propagation" {
  for_each = {
    for k, v in module.spoke_vpcs : k => v.transit_gateway_spoke_rt.id
    if contains(keys(var.central_vpcs), "shared_services")
  }

  transit_gateway_attachment_id  = module.central_vpcs["shared_services"].transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value
}

# If Hybrid DNS VPC is created, it propagates its CIDR to the Segment TGW Route Tables
resource "aws_ec2_transit_gateway_route_table_propagation" "hybrid_dns_to_spokes_propagation" {
  for_each = {
    for k, v in module.spoke_vpcs : k => v.transit_gateway_spoke_rt.id
    if contains(keys(var.central_vpcs), "hybrid_dns")
  }

  transit_gateway_attachment_id  = module.central_vpcs["hybrid_dns"].transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value
}

# ---------------------- AWS NETWORK FIREWALL ----------------------
module "aws_network_firewall" {
  count = local.create_anfw ? 1 : 0

  source  = "aws-ia/networkfirewall/aws"
  version = "= 0.0.2"

  network_firewall_name                     = var.central_vpcs.inspection.aws_network_firewall.name
  network_firewall_policy                   = var.central_vpcs.inspection.aws_network_firewall.policy_arn
  network_firewall_policy_change_protection = try(var.central_vpcs.inspection.aws_network_firewall.network_firewall_policy_change_protection, false)
  network_firewall_subnet_change_protection = try(var.central_vpcs.inspection.aws_network_firewall.network_firewall_subnet_change_protection, false)

  vpc_id                = module.central_vpcs["inspection"].vpc_attributes.id
  vpc_subnets           = { for k, v in module.central_vpcs["inspection"].private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "endpoints" }
  number_azs            = var.central_vpcs.inspection.az_count
  routing_configuration = local.anfw_routing_configuration[local.inspection_configuration]
}

# We need to get the CIDR blocks from a provided managed prefix list if:
# 1/ Network Firewall is deployed and,
# 2/ The Inspection VPC has public subnets.
data "aws_ec2_managed_prefix_list" "data_network_prefix_list" {
  count = local.network_pl ? 1 : 0

  id = var.network_definition.value
}