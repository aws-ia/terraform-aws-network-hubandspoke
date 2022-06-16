# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/locals.tf ---

locals {

  # Transit Gateway ID - either passed in the variables, or created in this module.
  transit_gateway_id = var.transit_gateway.id == null ? aws_ec2_transit_gateway.tgw[0].id : var.transit_gateway.id

  # Default definition of VPC Flow Logs (if not defined by user) - no destination
  vpc_flow_logs_default = {
    log_destination_type = "none"
  }

  # Definition of the subnets to create depending the type of central VPC
  subnet_config = {
    # Inspection VPC subnet definition, which will depend if public subnet(s) are created or not.
    inspection = local.inspection_subnet[contains(keys(try(var.central_vpcs.inspection.subnets, {})), "public") ? "with_internet" : "without_internet"]
    # Egress VPC subnet definition.
    egress = {
      public = merge(
        {
          name_prefix               = try(var.central_vpcs.egress.subnets.public.name_prefix, "public")                # Default value: "public"
          nat_gateway_configuration = try(var.central_vpcs.egress.subnets.public.nat_gateway_configuration, "all_azs") # Default value: NATGW created in all AZs
          route_to_transit_gateway  = ["10.0.0.0/8"]                                                                   # PLACEHOLDER
          tags                      = try(var.central_vpcs.egress.subnets.public.tags, {})
        },
        try(var.central_vpcs.egress.subnets.public, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.egress.subnets.transit_gateway.name_prefix, "tgw") # Default value: "public"
          route_to_nat                                    = try(var.central_vpcs.inspection.subnets.public.nat_gateway_configuration, "all_azs") != "none" ? true : false
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          tags                                            = try(var.central_vpcs.egress.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.egress.subnets.transit_gateway, {})
      )
    }
    # Shared Services VPC subnet definition.
    shared_services = {
      private = merge(
        {
          name_prefix              = try(var.central_vpcs.shared_services.subnets.endpoints.name_prefix, "endpoint") # Default value: "endpoint"
          route_to_nat             = false
          route_to_transit_gateway = ["0.0.0.0/0"]
          tags                     = try(var.central_vpcs.shared_services.subnets.endpoints.tags, {})
        },
        try(var.central_vpcs.shared_services.subnets.endpoints, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.shared_services.subnets.transit_gateway.name_prefix, "tgw") # Default value: "public"
          route_to_nat                                    = false
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          tags                                            = try(var.central_vpcs.shared_services.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.shared_services.subnets.transit_gateway, {})
      )
    }
    # Ingress VPC subnet definition, which will depend on the definition (or not) of private subnets.
    ingress = local.ingress_subnet[contains(keys(try(var.central_vpcs.ingress.subnets, {})), "private") ? "with_private" : "without_private"]
    # Hybrid DNS VPC subnet definition.
    hybrid_dns = {
      private = merge(
        {
          name_prefix              = try(var.central_vpcs.hybrid_dns.subnets.endpoints.name_prefix, "endpoint") # Default value: "endpoint"
          route_to_nat             = false
          route_to_transit_gateway = ["0.0.0.0/0"]
          tags                     = try(var.central_vpcs.hybrid_dns.subnets.endpoints.tags, {})
        },
        try(var.central_vpcs.hybrid_dns.subnets.endpoints, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.hybrid_dns.subnets.transit_gateway.name_prefix, "tgw") # Default value: "public"
          route_to_nat                                    = false
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          tags                                            = try(var.central_vpcs.hybrid_dns.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.hybrid_dns.subnets.transit_gateway, {})
      )
    }
  }

  # Inspection VPC Subnet configuration. Two options: with public subnets, and without public subnets
  inspection_subnet = {
    with_internet = {
      public = merge(
        {
          name_prefix               = try(var.central_vpcs.inspection.subnets.public.name_prefix, "public")                # Default value: "public"
          nat_gateway_configuration = try(var.central_vpcs.inspection.subnets.public.nat_gateway_configuration, "all_azs") # Default value: NATGW created in all AZs
          tags                      = try(var.central_vpcs.inspection.subnets.public.tags, {})
        },
        try(var.central_vpcs.inspection.subnets.public, {})
      )
      private = merge(
        {
          name_prefix              = try(var.central_vpcs.inspection.subnets.inspection.name_prefix, "inspection") # Default value: "inspection"
          route_to_nat             = try(var.central_vpcs.inspection.subnets.public.nat_gateway_configuration, "all_azs") != "none" ? true : false
          route_to_transit_gateway = ["10.0.0.0/8"] # PLACEHOLDER
          tags                     = try(var.central_vpcs.inspection.subnets.inspection.tags, {})
        },
        try(var.central_vpcs.inspection.subnets.inspection, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.inspection.subnets.transit_gateway.name_prefix, "tgw") # Default value: "public"
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          tags                                            = try(var.central_vpcs.inspection.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.inspection.subnets.transit_gateway, {})
      )
    }
    without_internet = {
      private = merge(
        {
          name_prefix              = try(var.central_vpcs.inspection.subnets.inspection.name_prefix, "inspection") # Default value: "inspection"
          route_to_nat             = false
          route_to_transit_gateway = ["0.0.0.0/0"]
          tags                     = try(var.central_vpcs.inspection.subnets.inspection.tags, {})
        },
        try(var.central_vpcs.inspection.subnets.inspection, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.inspection.subnets.transit_gateway.name_prefix, "tgw") # Default value: "public"
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          tags                                            = try(var.central_vpcs.inspection.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.inspection.subnets.transit_gateway, {})
      )
    }
  }

  # Ingress VPC Subnet configuration. Two options: with private subnets, and without private subnets
  ingress_subnet = {
    with_private = {
      public = merge(
        {
          name_prefix               = try(var.central_vpcs.ingress.subnets.public.name_prefix, "public")             # Default value: "public"
          nat_gateway_configuration = try(var.central_vpcs.ingress.subnets.public.nat_gateway_configuration, "none") # Default value: NO NATGWs in Ingress VPC
          tags                      = try(var.central_vpcs.ingress.subnets.public.tags, {})
        },
        try(var.central_vpcs.ingress.subnets.public, {})
      )
      private = merge(
        {
          name_prefix              = try(var.central_vpcs.ingress.subnets.private.name_prefix, "private") # Default value: "private"
          route_to_transit_gateway = ["10.0.0.0/8"]                                                       # PLACEHOLDER
          tags                     = try(var.central_vpcs.ingress.subnets.private.tags, {})
        },
        try(var.central_vpcs.ingress.subnets.private, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.ingress.subnets.transit_gateway.name_prefix, "tgw") # Default value: "public"
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          tags                                            = try(var.central_vpcs.ingress.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.ingress.subnets.transit_gateway, {})
      )
    }
    without_private = {
      public = merge(
        {
          name_prefix               = try(var.central_vpcs.ingress.subnets.public.name_prefix, "public")             # Default value: "public"
          nat_gateway_configuration = try(var.central_vpcs.ingress.subnets.public.nat_gateway_configuration, "none") # Default value: NO NATGWs in Ingress VPC
          route_to_transit_gateway  = ["10.0.0.0/8"]                                                                 # PLACEHOLDER
          tags                      = try(var.central_vpcs.ingress.subnets.public.tags, {})
        },
        try(var.central_vpcs.ingress.subnets.public, {})
      )
      transit_gateway = merge(
        {
          name_prefix                                     = try(var.central_vpcs.ingress.subnets.transit_gateway.name_prefix, "tgw") # Default value: "public"
          transit_gateway_id                              = local.transit_gateway_id
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          tags                                            = try(var.central_vpcs.ingress.subnets.transit_gateway.tags, {})
        },
        try(var.central_vpcs.ingress.subnets.transit_gateway, {})
      )
    }
  }
}