# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- modules/tgw_rt/main.tf ---

# POST-INSPECTION TGW ROUTE TABLE
resource "aws_ec2_transit_gateway_route_table" "post_inspection_rt" {
  count              = var.inspection_vpc ? 1 : 0
  transit_gateway_id = var.tgw_id

  tags = {
    Name = "tgw_post-inspection_rt-${var.identifier}"
  }
}

# Inspection VPC Attachment to Post-Inspection Route Table
resource "aws_ec2_transit_gateway_route_table_association" "inspection_vpc_assoc" {
  count                          = var.inspection_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.inspection_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection_rt[0].id
}

# If Egress VPC is created, adding a static route sending 0.0.0.0/0 to that VPC
resource "aws_ec2_transit_gateway_route" "inspection_to_internet" {
  count                          = var.egress_vpc && var.inspection_vpc ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.egress_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection_rt[0].id
}

# If Central Endpoints / DNS VPC is created, propagate its attachment to the post-inspection RT
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_endpoints_propagation" {
  count                          = var.endpoints_vpc && var.inspection_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.endpoints_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection_rt[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_dns_propagation" {
  count                          = var.dns_vpc && var.inspection_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.dns_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection_rt[0].id
}

# Propagation of Spoke VPCs
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_spokes_propagation" {
  for_each = {
    for key, value in var.spoke_tgw_attachments : key => value
    if var.inspection_vpc
  }
  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection_rt[0].id
}

# INGRESS TGW ROUTE TABLE
resource "aws_ec2_transit_gateway_route_table" "ingress_rt" {
  count              = var.ingress_vpc ? 1 : 0
  transit_gateway_id = var.tgw_id

  tags = {
    Name = "tgw_ingress_rt-${var.identifier}"
  }
}

# Ingress VPC Attachment to Ingress Route Table
resource "aws_ec2_transit_gateway_route_table_association" "ingress_vpc_assoc" {
  count                          = var.ingress_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.ingress_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ingress_rt[0].id
}

# If Inspection VPC is created, all the ingress traffic gets first inspected
resource "aws_ec2_transit_gateway_route" "ingress_to_inspection" {
  count                          = var.inspection_vpc && var.ingress_vpc ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.inspection_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ingress_rt[0].id
}

# If there's no Inspection VPC, propagate Endpoints and DNS VPCs (if created)
resource "aws_ec2_transit_gateway_route_table_propagation" "ingress_endpoints_propagation" {
  count                          = !var.inspection_vpc && var.endpoints_vpc && var.ingress_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.endpoints_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ingress_rt[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "ingress_dns_propagation" {
  count                          = !var.inspection_vpc && var.dns_vpc && var.ingress_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.dns_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ingress_rt[0].id
}

# If Inspection VPC is not created, all the Spoke VPCs created propagate their CIDR blocks
resource "aws_ec2_transit_gateway_route_table_propagation" "ingress_spokes_propagation" {
  for_each = {
    for key, value in var.spoke_tgw_attachments : key => value
    if !var.inspection_vpc && var.ingress_vpc
  }
  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ingress_rt[0].id
}

# ENDPOINTS TGW ROUTE TABLE
resource "aws_ec2_transit_gateway_route_table" "endpoints_rt" {
  count              = var.endpoints_vpc ? 1 : 0
  transit_gateway_id = var.tgw_id

  tags = {
    Name = "tgw_endpoints_rt-${var.identifier}"
  }
}

# Endpoints VPC Attachment to Endpoints Route Table
resource "aws_ec2_transit_gateway_route_table_association" "endpoints_vpc_assoc" {
  count                          = var.endpoints_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.endpoints_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.endpoints_rt[0].id
}

# If Inspection VPC is created, all the traffic needs to be inspected first
resource "aws_ec2_transit_gateway_route" "endpoints_to_inspection" {
  count                          = var.inspection_vpc && var.endpoints_vpc ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.inspection_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.endpoints_rt[0].id
}

# If there's no Inspection VPC, propagate DNS VPCs (if created)
resource "aws_ec2_transit_gateway_route_table_propagation" "endpoints_dns_propagation" {
  count                          = !var.inspection_vpc && var.endpoints_vpc && var.dns_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.dns_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.endpoints_rt[0].id
}

# If Inspection VPC is not created, all the Spoke VPCs created propagate their CIDR blocks
resource "aws_ec2_transit_gateway_route_table_propagation" "endpoints_spokes_propagation" {
  for_each = {
    for key, value in var.spoke_tgw_attachments : key => value
    if !var.inspection_vpc && var.endpoints_vpc
  }
  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.endpoints_rt[0].id
}

# DNS TGW ROUTE TABLE
resource "aws_ec2_transit_gateway_route_table" "dns_rt" {
  count              = var.dns_vpc ? 1 : 0
  transit_gateway_id = var.tgw_id

  tags = {
    Name = "tgw_dns_rt-${var.identifier}"
  }
}

# DNS VPC Attachment to DNS Route Table
resource "aws_ec2_transit_gateway_route_table_association" "dns_vpc_assoc" {
  count                          = var.dns_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.dns_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dns_rt[0].id
}

# If Inspection VPC is created, all the traffic needs to be inspected first
resource "aws_ec2_transit_gateway_route" "dns_to_inspection" {
  count                          = var.inspection_vpc && var.dns_vpc ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.inspection_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dns_rt[0].id
}

# If there's no Inspection VPC, propagate Endpoints VPCs (if created)
resource "aws_ec2_transit_gateway_route_table_propagation" "dns_endpoints_propagation" {
  count                          = !var.inspection_vpc && var.endpoints_vpc && var.dns_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.endpoints_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dns_rt[0].id
}

# If Inspection VPC is not created, all the Spoke VPCs created propagate their CIDR blocks
resource "aws_ec2_transit_gateway_route_table_propagation" "dns_spokes_propagation" {
  for_each = {
    for key, value in var.spoke_tgw_attachments : key => value
    if !var.inspection_vpc && var.dns_vpc
  }
  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dns_rt[0].id
}

# SPOKE VPC TGW ROUTE TABLE
resource "aws_ec2_transit_gateway_route_table" "spoke_vpc_rt" {
  transit_gateway_id = var.tgw_id

  tags = {
    Name = "spoke_vpc_rt-${var.identifier}"
  }
}

# Spoke VPCs attachment association
resource "aws_ec2_transit_gateway_route_table_association" "spoke_vpc_assoc" {
  for_each                       = var.spoke_tgw_attachments
  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_vpc_rt.id
}

# If Inspection VPC is created, all the traffic needs to be inspected first
resource "aws_ec2_transit_gateway_route" "spokes_to_inspection" {
  count                          = var.inspection_vpc ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.inspection_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_vpc_rt.id
}

# If Inspection VPC is not created, the other Central VPCs propagate their route (if created)
resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_endpoints_propagation" {
  count                          = !var.inspection_vpc && var.endpoints_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.endpoints_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_vpc_rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_dns_propagation" {
  count                          = !var.inspection_vpc && var.dns_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.dns_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_vpc_rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_egress_propagation" {
  count                          = !var.inspection_vpc && var.egress_vpc ? 1 : 0
  transit_gateway_attachment_id  = var.egress_tgw_attachment
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_vpc_rt.id
}



