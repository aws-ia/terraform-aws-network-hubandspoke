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

# --------- TRANSIT GATEWAY ROUTE TABLE AND ASSOCATIONS - SPOKE VPCS ---------
resource "aws_ec2_transit_gateway_route_table" "spokes_tgw_rt" {
  transit_gateway_id = local.transit_gateway_id

  tags = {
    Name = "spoke-vpc-tgw-rt-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "spokes_tgw_rt_association" {
  for_each = { for k, v in try(var.spoke_vpcs.vpc_information, {}) : k => v.transit_gateway_attachment_id if contains(keys(k), "transit_gateway_attachment_id") }

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_tgw_rt.id
}

# ASSOCIATION TO VPCS WHEN SPOKE VPCS ARE SUPPORTED

# ---------------------- TRANSIT GATEWAY STATIC ROUTES ----------------------
# # If both Inspection and Egress VPCs are created, the Inspection TGW Route Table will have a static route to 0.0.0.0/0 with the Egress VPC as destination
# resource "aws_ec2_transit_gateway_route" "inspection_to_egress_route" {
#   count = length(setintersection(keys(var.central_vpcs), ["inspection", "egress"])) == 2 ? 1 : 0

#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_attachment_id  = module.central_vpcs["egress"].transit_gateway_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["inspection"].id
# }

# # If both Inspection and Egress VPC are created, the Egress TGW Route Table should only have one route sending all the traffic to the Inspection VPC
# resource "aws_ec2_transit_gateway_route" "egress_to_inspection_route" {
#   count = length(setintersection(keys(var.central_vpcs), ["inspection", "egress"])) == 2 ? 1 : 0

#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_attachment_id  = module.central_vpcs["inspection"].transit_gateway_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["egress"].id
# }

# # If both Inspection and Ingress VPC are created, the Ingress TGW Route Table should have a 0.0.0.0/0 route to the Inspection VPC
# resource "aws_ec2_transit_gateway_route" "ingress_to_inspection_route" {
#   count = length(setintersection(keys(var.central_vpcs), ["inspection", "ingress"])) == 2 ? 1 : 0

#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_attachment_id  = module.central_vpcs["inspection"].transit_gateway_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_route_table["ingress"].id
# }

# # In the Spoke VPCs, the default 0.0.0.0/0 static route destination is going to depend on the existence of the Inspection and Egress VPC
# # - If the Inspection VPC is created, regardless of the creation of the Egress VPC, the traffic from the Spoke VPCs will be routed to the Inspection VPC.
# # - The default route to 0.0.0.0/0 from the Spoke VPCs will only be routed to the Egress VPC if there's no Inspection VPC created.
# # - This route won't exist if there's not Inspection and Egress VPC
# resource "aws_ec2_transit_gateway_route" "spokes_static_default_route" {
#   count = length(setintersection(keys(var.central_vpcs), ["inspection", "egress"])) > 0 ? 1 : 0

#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_attachment_id  = contains(keys(var.central_vpcs), "inspection") ? module.central_vpcs["inspection"].transit_gateway_attachment_id : module.central_vpcs["egress"].transit_gateway_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_tgw_rt.id
# }

# -------------------- TRANSIT GATEWAY PROPAGATED ROUTES --------------------
# If the Inspection VPC is created and there's no Egress VPC, all the Spoke VPCs propagate to the Inspection TGW Route Table
#  TO ADD WHEN SUPPORTING SPOKE VPCs

# If the Egress VPC is created and there's no Inspection VPC, all the Spoke VPCs propagate to the Egress TGW Route Table
#  TO ADD WHEN SUPPORTING SPOKE VPCs

# If the Shared Services VPC is created, all the Spokes VPCs propagate to the Shared Services TGW Route Table
#  TO ADD WHEN SUPPORTING SPOKE VPCs

# If there's no Inspection VPC created, all the Spoke VPCs propagate to the Ingress TGW Route Table
#  TO ADD WHEN SUPPORTING SPOKE VPCs

# If the Hybrid DNS VPC is created, all the Spokes VPCs propagate to the Hybrid DNS TGW Route Table
#  TO ADD WHEN SUPPORTING SPOKE VPCs

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

# ---------------------- PREFIX LIST - IF SUPERNET CIDR BLOCK OR PREFIX LIST IS NOT PROVIDED ----------------------
data "aws_vpc" "spoke_vpcs" {
  for_each = { for k, v in try(var.spoke_vpcs.vpc_information, {}) : k => v if local.create_pl }

  id = each.value.vpc_id
}

resource "aws_ec2_managed_prefix_list" "network_prefix_list" {
  count = local.create_pl ? 1 : 0

  name           = "Network's Prefix List (managed by Hub and Spoke module)."
  address_family = "IPv4"
  max_entries    = length(keys(var.spoke_vpcs.vpc_information))
}

resource "aws_ec2_managed_prefix_list_entry" "entry" {
  for_each = { for k, v in data.aws_vpc.spoke_vpcs : k => v if local.create_pl }

  cidr           = each.value.cidr_block
  description    = each.key
  prefix_list_id = aws_ec2_managed_prefix_list.network_prefix_list[0].id
}

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