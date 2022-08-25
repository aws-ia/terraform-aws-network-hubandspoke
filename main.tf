# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/main.tf ---

# ---------------- AWS TRANSIT GATEWAY ----------------
resource "aws_ec2_transit_gateway" "tgw" {
  count = local.create_tgw ? 1 : 0

  description                     = "Transit_Gateway-${var.identifier}"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  amazon_side_asn                 = try(var.transit_gateway.amazon_side_asn, 64512)
  auto_accept_shared_attachments  = try(var.transit_gateway.auto_accept_shared_attachments, "disable")
  dns_support                     = try(var.transit_gateway.dns_support, "enable")
  multicast_support               = try(var.transit_gateway.multicast_support, "disable")
  transit_gateway_cidr_blocks     = try(var.transit_gateway.transit_gateway_cidr_blocks, [])
  vpn_ecmp_support                = try(var.transit_gateway.vpn_ecmp_support, "enable")

  tags = merge({
    Name = try(var.transit_gateway.name, "tgw-${var.identifier}")
  }, try(var.transit_gateway.tags, {}))
}

# ---------------- CENTRAL VPCs ----------------
module "central_vpcs" {
  for_each = var.central_vpcs

  source  = "aws-ia/vpc/aws"
  version = "= 2.5.0"

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

# --------- TRANSIT GATEWAY ROUTE TABLE, ASSOCATIONS, AND PREFIX LIST (IF APPLIES) - SPOKE VPCS ---------
module "spoke_vpcs" {
  for_each = try(var.spoke_vpcs.vpc_information, {})
  source = "./modules/spoke_vpcs"

  identifier = var.identifier
  transit_gateway_id = local.transit_gateway_id

  segment_name = each.key
  segment_information = each.value
}

# ASSOCIATION TO VPCS WHEN SPOKE VPCS ARE SUPPORTED

# ---------------------- TRANSIT GATEWAY STATIC ROUTES ----------------------
# # Static Route (0.0.0.0/0) from Spoke VPCs to Inspection VPC if:
# # 1/ The Inspection VPC is created and no Egress VPC is created.
# # 2/ Both Inspection VPC and Egress VPC are created, and the traffic inspection is "all" or "north-south".
# resource "aws_ec2_transit_gateway_route" "spokes_to_inspection_default_route" {
#   count = local.spoke_to_inspection_default ? 1 : 0

#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_attachment_id  = module.central_vpcs["inspection"].transit_gateway_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_tgw_rt.id
# }

# # Static Route (0.0.0.0/0) from Spoke VPCs to Egress VPC if:
# # 1/ The Egress VPC is created and no Inspection VPC is created.
# # 2/ Both Inspection VPC and Egress VPC are created, and the traffic inspection is "east-west".
# resource "aws_ec2_transit_gateway_route" "spokes_to_inspection_default_route" {
#   count = local.spoke_to_egress_default ? 1 : 0

#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_attachment_id  = module.central_vpcs["egress"].transit_gateway_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_tgw_rt.id
# }



# -------------------- TRANSIT GATEWAY PROPAGATED ROUTES --------------------

# # If Shared Services VPC is created, it propagates its CIDR to the Spoke VPC TGW Route Table
# resource "aws_ec2_transit_gateway_route_table_propagation" "shared_services_to_spokes_propagation" {
#   count = try(var.central_vpcs.shared_services, "none") == "none" ? 0 : 1

#   transit_gateway_attachment_id  = module.central_vpcs["shared_services"].transit_gateway_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_tgw_rt.id
# }

# # If Hybrid DNS VPC is created, it propagates its CIDR to the Spoke VPC TGW Route Table
# resource "aws_ec2_transit_gateway_route_table_propagation" "hybrid_dns_to_spokes_propagation" {
#   count = try(var.central_vpcs.hybrid_dns, "none") == "none" ? 0 : 1

#   transit_gateway_attachment_id  = module.central_vpcs["hybrid_dns"].transit_gateway_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_tgw_rt.id
# }

# ---------------------- AWS NETWORK FIREWALL ----------------------
module "aws_network_firewall" {
  count = local.create_anfw ? 1 : 0

  source  = "aws-ia/networkfirewall/aws"
  version = "= 0.0.1"

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
# 1/ Network Firewall is deployed. 
# 2/ The Inspection VPC has public subnets.
data "aws_ec2_managed_prefix_list" "data_network_prefix_list" {
  count = local.prefix_list_to_cidrs ? 1 : 0

  id = var.spoke_vpcs.network_prefix_list
}