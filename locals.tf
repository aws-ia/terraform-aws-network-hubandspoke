# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/locals.tf ---

locals {
  # ---------- TRANSIT GATEWAY LOCAL VARIABLES ----------
  # Boolean to indicate if a new Transit Gateway needs to be created or not
  create_tgw         = try(var.transit_gateway.id, "create") == "create" ? true : false
  transit_gateway_id = local.create_tgw ? aws_ec2_transit_gateway.tgw[0].id : var.transit_gateway.id

  # ---------- DEFAULT DEFINITION OF VPC FLOW LOGS (NO DESTINATION) ----------
  vpc_flow_logs_default = {
    log_destination_type = "none"
  }

  # ---------- AWS NETWORK FIREWALL LOCAL VARIABLES ----------
  # Boolean to indicate if a new AWS Network Firewall needs to be created or not
  create_anfw = contains(try(var.central_vpcs.inspection, {}), "aws_network_firewall")

  # ---------- SPOKE VPC LOCAL VARIABLES ----------
  # Boolean to determine if a managed prefix list should be created by the Hub and Spoke module (neither `network_cidr_block` or `network_prefix_list` have been defined)
  create_pl = length(setintersection(keys(var.spoke_vpcs), ["network_cidr_block", "network_prefix_list"])) == 0 ? true : false
  # Boolean to indicate if the network's route definition is done with a managed prefix list (for the Transit Gateway Route Tables)
  network_pl = local.create_pl || (try(var.spoke_vpcs.network_prefix_list, "empty") != "empty")
  # Destination route to indicate in the VPC routes or Transit Gateway Route Tables
  network_route = local.create_pl ? aws_ec2_managed_prefix_list.network_prefix_list[0].id : (local.network_pl ? var.spoke_vpcs.network_prefix_list : var.spoke_vpc.network_cidr_block)

  # ---------- CENTRAL VPC LOCAL VARIABLES ----------
  # Inspection / Shared Services VPC configuration
  inspection_configuration      = contains(keys(try(var.central_vpcs.inspection.subnets, {})), "public") ? "with_internet" : "without_internet"
  shared_services_configuration = contains(keys(try(var.central_vpcs.shared_services.subnets, {})), "dns") ? "with_dns" : "without_dns"

  # Subnet configuration (all Central VPCs)
  subnet_config = {
    inspection      = local.inspection_subnet[local.inspection_configuration]
    egress          = local.egress_subnet
    shared_services = local.shared_services_subnet[local.shared_services_configuration]
    ingress         = local.ingress_subnet
    hybrid_dns      = local.hybrid_dns_subnet
  }

  # Inspection VPC Subnet configuration. Two options: with public subnets, and without public subnets
  inspection_subnet = {
    with_internet = {
      public = merge(
        {
          name_prefix               = try(var.central_vpcs.inspection.subnets.public.name_prefix, "inspection-vpc-public")
          nat_gateway_configuration = try(var.central_vpcs.inspection.subnets.public.nat_gateway_configuration, "all_azs")
          tags                      = try(var.central_vpcs.inspection.subnets.public.tags, {})
        },
        try(var.central_vpcs.inspection.subnets.public, {})
      )
      endpoints = merge(
        {
          name_prefix              = try(var.central_vpcs.inspection.subnets.endpoints.name_prefix, "inspection-vpc-endpoints")
          connect_to_public_natgw  = try(var.central_vpcs.inspection.subnets.public.nat_gateway_configuration, "all_azs") != "none" ? true : false
          route_to_transit_gateway = local.network_route
          tags                     = try(var.central_vpcs.inspection.subnets.endpoints.tags, {})
        },
        try(var.central_vpcs.inspection.subnets.endpoints, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.inspection.subnets.transit_gateway.name_prefix, "inspection-vpc-tgw")
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          transit_gateway_appliance_mode_support          = "enable"
          tags                                            = try(var.central_vpcs.inspection.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.inspection.subnets.transit_gateway, {})
      )
    }
    without_internet = {
      endpoints = merge(
        {
          name_prefix              = try(var.central_vpcs.inspection.subnets.endoints.name_prefix, "inspection-vpc-endpoints")
          connect_to_public_natgw  = false
          route_to_transit_gateway = "0.0.0.0/0"
          tags                     = try(var.central_vpcs.inspection.subnets.endpoints.tags, {})
        },
        try(var.central_vpcs.inspection.subnets.endpoints, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.inspection.subnets.transit_gateway.name_prefix, "inspection-vpc-tgw")
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          transit_gateway_appliance_mode_support          = "enable"
          tags                                            = try(var.central_vpcs.inspection.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.inspection.subnets.transit_gateway, {})
      )
    }
  }

  # Egress VPC Subnet configuration.
  egress_subnet = {
    public = merge(
      {
        name_prefix               = try(var.central_vpcs.egress.subnets.public.name_prefix, "egress-vpc-public")
        nat_gateway_configuration = try(var.central_vpcs.egress.subnets.public.nat_gateway_configuration, "all_azs")
        route_to_transit_gateway  = local.network_route
        tags                      = try(var.central_vpcs.egress.subnets.public.tags, {})
      },
      try(var.central_vpcs.egress.subnets.public, {})
    )
    transit_gateway = merge(
      {
        name_prefix                                     = try(var.central_vpcs.egress.subnets.transit_gateway.name_prefix, "egress-vpc-tgw")
        connect_to_public_natgw                         = try(var.central_vpcs.inspection.subnets.public.nat_gateway_configuration, "all_azs") != "none" ? true : false
        transit_gateway_id                              = local.transit_gateway_id
        transit_gateway_default_route_table_association = false
        transit_gateway_default_route_table_propagation = false
        tags                                            = try(var.central_vpcs.egress.subnets.transit_gateway.tags, {})
      },
      try(var.central_vpcs.egress.subnets.transit_gateway, {})
    )
  }

  # Shared Services VPC Subnet configuration.
  shared_services_subnet = {
    with_dns = {
      endpoints = merge(
        {
          name_prefix              = try(var.central_vpcs.shared_services.subnets.endpoints.name_prefix, "shared-services-vpc-endpoints")
          route_to_transit_gateway = "0.0.0.0/0"
          tags                     = try(var.central_vpcs.shared_services.subnets.endpoints.tags, {})
        },
        try(var.central_vpcs.shared_services.subnets.endpoints, {})
      )
      dns = merge(
        {
          name_prefix              = try(var.central_vpcs.shared_services.subnets.dns.name_prefix, "shared-services-vpc-dns")
          route_to_transit_gateway = "0.0.0.0/0"
          tags                     = try(var.central_vpcs.shared_services.subnets.dns.tags, {})
        },
        try(var.central_vpcs.shared_services.subnets.dns, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.shared_services.subnets.transit_gateway.name_prefix, "shared-services-vpc-tgw")
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          tags                                            = try(var.central_vpcs.shared_services.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.shared_services.subnets.transit_gateway, {})
      )
    }
    without_dns = {
      endpoints = merge(
        {
          name_prefix              = try(var.central_vpcs.shared_services.subnets.endpoints.name_prefix, "shared-services-vpc-endpoints")
          route_to_transit_gateway = "0.0.0.0/0"
          tags                     = try(var.central_vpcs.shared_services.subnets.endpoints.tags, {})
        },
        try(var.central_vpcs.shared_services.subnets.endpoints, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.shared_services.subnets.transit_gateway.name_prefix, "shared-services-vpc-tgw")
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          tags                                            = try(var.central_vpcs.shared_services.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.shared_services.subnets.transit_gateway, {})
      )
    }
  }

  # Ingress VPC Subnet configuration.
  ingress_subnet = {
    public = merge(
      {
        name_prefix               = try(var.central_vpcs.ingress.subnets.public.name_prefix, "ingress-vpc-public")
        nat_gateway_configuration = try(var.central_vpcs.ingress.subnets.public.nat_gateway_configuration, "none")
        route_to_transit_gateway  = local.network_route
        tags                      = try(var.central_vpcs.ingress.subnets.public.tags, {})
      },
      try(var.central_vpcs.ingress.subnets.public, {})
    )
    transit_gateway = merge(
      {
        name_prefix                                     = try(var.central_vpcs.ingress.subnets.transit_gateway.name_prefix, "ingress-vpc-tgw")
        connect_to_public_natgw                         = false
        transit_gateway_id                              = local.transit_gateway_id
        transit_gateway_default_route_table_association = false
        transit_gateway_default_route_table_propagation = false
        tags                                            = try(var.central_vpcs.ingress.subnets.transit_gateway.tags, {})
      },
      try(var.central_vpcs.ingress.subnets.transit_gateway, {})
    )
  }

  # Hybrid DNS Subnet configuration.
  hybrid_dns_subnet = {
    endpoints = merge(
      {
        name_prefix              = try(var.central_vpcs.hybrid_dns.subnets.endpoints.name_prefix, "hybrid-dns-endpoint")
        route_to_transit_gateway = "0.0.0.0/0"
        tags                     = try(var.central_vpcs.hybrid_dns.subnets.endpoints.tags, {})
      },
      try(var.central_vpcs.hybrid_dns.subnets.endpoints, {})
    )
    transit_gateway = merge(
      {
        name_prefix                                     = try(var.central_vpcs.hybrid_dns.subnets.transit_gateway.name_prefix, "hybrid-dns-tgw")
        transit_gateway_id                              = local.transit_gateway_id
        transit_gateway_default_route_table_association = false
        transit_gateway_default_route_table_propagation = false
        tags                                            = try(var.central_vpcs.hybrid_dns.subnets.transit_gateway.tags, {})
      },
      try(var.central_vpcs.hybrid_dns.subnets.transit_gateway, {})
    )
  }
}