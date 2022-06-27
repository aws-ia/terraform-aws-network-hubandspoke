# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/variables.tf ---

# Module identifier
variable "identifier" {
  type        = string
  description = "String to identify the whole Hub and Spoke Architecture"
}

# AWS Transit Gateway Information
variable "transit_gateway" {
  description = <<-EOF
  Transit Gateway configuration. Either you specify the `id` of a current Transit Gateway you created, or you the `configuration` variables to create a new one. 
  The following parameters are accepted when configuring a new Transit Gateway:
  - `name`                           = (Optional|String) Name of the new Transit Gateway to create.
  - `amazon_side_asn`                = (Optional|Int) Private Autonomous System Number (ASN) for the Amazon side of a BGP session. The range is `64512` to `65534` for 16-bit ASNs and `4200000000` to `4294967294` for 32-bit ASNs. Default value: `64512`.
  - `auto_accept_shared_attachments` = (Optional|String) Whether resource attachment requests are automatically accepted. Valid values: `disable`, `enable`. Default value: `disable`.
  - `dns_support`                    = (Optional|String) Whether DNS support is enabled. Valid values: `disable`, `enable`. Default value: `enable`.
  - `vpn_ecmp_support`               = (Optional|String) Whether VPN Equal Cost Multipath Protocol support is enabled. Valid values: `disable`, `enable`. Default value: `enable`.
  - `resource_share`                 = (Optional|Bool) Whether the Transit Gateway is shared via Resource Access Manager or not. Valid values: `false`, `true`. Default value: `false`.
  - `tags`                           = (Optional|map(string)) Tags to apply to the Transit Gateway.
EOF
  type        = any

  # ---------------- VALID KEYS FOR var.transit_gateway ----------------
  validation {
    error_message = "Only valid key values for var.transit_gateway: \"id\", \"configuration\"."
    condition = length(setsubtract(keys(var.transit_gateway), [
      "id",
      "configuration"
    ])) == 0
  }

  # If ID is specified, no other values are allowed
  validation {
    condition     = length(setintersection(keys(var.transit_gateway), ["id", "configuration"])) < 2
    error_message = "You need to define either the configuration of a new Transit Gateway (name ), or ID of a current one."
  }

  # ---------------- VALID KEYS FOR var.transit_gateway.configuration ----------------
  validation {
    error_message = "Only valid key values for var.transit_gateway.configuration: \"name\", \"amazon_side_asn\", \"auto_accept_shared_attachments\", \"description\", \"dns_support\", \"vpn_ecmp_support\", \"resource_share\", \"tags\"."
    condition = length(setsubtract(keys(try(var.transit_gateway.configuration, {})), [
      "name",
      "amazon_side_asn",
      "auto_accept_shared_attachments",
      "dns_support",
      "vpn_ecmp_support",
      "resource_share",
      "tags"
    ])) == 0
  }
}

# Central VPCs
variable "central_vpcs" {
  description = <<-EOF
  Configuration of the Central VPCs - used to centralized different services. You can create the following Central VPCs: 
  - `inspection`      = To centralize the traffic inspection. If created, all the traffic between Spoke VPCs (East/West) and to the Internet (North/South) will be passed to this VPC. You can create Internet access in this VPC, if no Egress VPC is created.
  - `egress`          = To centralize Internet access. You cannot create an Egress VPC and an Inspection VPC with Internet access at the same time.
  - `shared_services` = To centralize VPC endpoint access. This VPC won't have Internet access, and its TGW attachment will be propaged directly to the Spoke TGW Route Table directly.
  - `ingress`         = To centralize ingress access to resources from a central VPC - no distributed Internet access.
  - `hybrid_dns`      = To centralize Hybrid DNS configuration (Route 53 Resolver endpoints or a 3rd-party solution) outside of the Shared Services VPC. This VPC won't have Internet access, and its TGW attachment will be propaged directly to the Spoke TGW Route Table directly.
  
  For more information of the input format and the resources created in each Central VPC, check the section **Central VPCs** in the README.
EOF
  type        = any

  # ---------------- VALID KEYS FOR var.central_vpcs ----------------
  validation {
    error_message = "Only valid key values for central_vpcs: \"inspection\", \"egress\", \"shared_services\", \"ingress\", or \"hybrid_dns\"."
    condition = length(setsubtract(keys(var.central_vpcs), [
      "inspection",
      "egress",
      "shared_services",
      "ingress",
      "hybrid_dns"
    ])) == 0
  }

  #  ---------------- INSPECTION VPC (IF DEFINED) CANNOT HAVE A PUBLIC SUBNET IF EGRESS VPC IS DEFINED ----------------
  validation {
    error_message = "If you create an Inspection and Egress VPC at the same time, the Inspection VPC cannot have Internet access - remove the definition of public subnet(s)."
    condition     = (contains(keys(try(var.central_vpcs, {})), "egress") && !contains(keys(try(var.central_vpcs.inspection.subnets, {})), "public")) || !contains(keys(try(var.central_vpcs, {})), "egress")
  }

  # ---------------- VALIDATION OF INSPECTION VPC ----------------
  # Valid keys for var.central_vpcs.inspection
  validation {
    error_message = "Only valid key values for the Inspection VPC: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"vpc_flow_logs\", \"subnets\", \"aws_network_firewall\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.inspection, {})), [
      "name",
      "vpc_id",
      "cidr_block",
      "vpc_secondary_cidr",
      "az_count",
      "vpc_enable_dns_hostnames",
      "vpc_enable_dns_support",
      "vpc_instance_tenancy",
      "vpc_ipv4_ipam_pool_id",
      "vpc_ipv4_netmask_length",
      "vpc_flow_logs",
      "subnets",
      "aws_network_firewall",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.inspection.subnets
  validation {
    error_message = "For var.central_vpcs.inspection.subnets, you can only define \"public\", \"inspection\", and \"transit_gateway\" subnets."
    condition = length(setsubtract(keys(try(var.central_vpcs.inspection.subnets, {})), [
      "public",
      "inspection",
      "transit_gateway"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.inspection.subnets.public
  validation {
    error_message = "For Public Subnets in Inspection VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"nat_gateway_configuration\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.inspection.subnets.public, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "nat_gateway_configuration",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.inspection.subnets.inspection
  validation {
    error_message = "For Inspection Subnets in Inspection VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"route_to_transit_gateway\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.inspection.subnets.inspection, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "route_to_transit_gateway",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.inspection.subnets.transit_gateway
  validation {
    error_message = "For TGW Subnets in Inspection VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.inspection.subnets.transit_gateway, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.inspection.aws_network_firewall
  validation {
    error_message = "Allowed keys to configure AWS Network Firewall: \"name\", \"firewall_policy\", \"firewall_policy_change_protection\", \"subnet_change_protection\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.inspection.aws_network_firewall, {})), [
      "name",
      "firewall_policy",
      "firewall_policy_change_protection",
      "subnet_change_protection",
      "tags"
    ])) == 0
  }

  # ---------------- VALIDATION OF EGRESS VPC ----------------
  # Valid keys for var.central_vpcs.egress
  validation {
    error_message = "Only valid key values for the Egress VPC: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"vpc_flow_logs\", \"subnets\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.egress, {})), [
      "name",
      "vpc_id",
      "cidr_block",
      "vpc_secondary_cidr",
      "az_count",
      "vpc_enable_dns_hostnames",
      "vpc_enable_dns_support",
      "vpc_instance_tenancy",
      "vpc_ipv4_ipam_pool_id",
      "vpc_ipv4_netmask_length",
      "vpc_flow_logs",
      "subnets",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.egress.subnets
  validation {
    error_message = "For var.central_vpcs.egress.subnets, you can only define \"public\", and \"transit_gateway\" subnets."
    condition = length(setsubtract(keys(try(var.central_vpcs.egress.subnets, {})), [
      "public",
      "transit_gateway"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.egress.subnets.public
  validation {
    error_message = "For Public Subnets in Egress VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"nat_gateway_configuration\", \"route_to_transit_gateway\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.egress.subnets.public, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "nat_gateway_configuration",
      "route_to_transit_gateway",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.egress.subnets.transit_gateway
  validation {
    error_message = "For TGW Subnets in Egress VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.egress.subnets.transit_gateway, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }

  # ---------------- VALIDATION OF SHARED SERVICES VPC ----------------
  # Valid keys for var.central_vpcs.shared_services
  validation {
    error_message = "Only valid key values for the Shared Services VPC: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"vpc_flow_logs\", \"subnets\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.shared_services, {})), [
      "name",
      "vpc_id",
      "cidr_block",
      "vpc_secondary_cidr",
      "az_count",
      "vpc_enable_dns_hostnames",
      "vpc_enable_dns_support",
      "vpc_instance_tenancy",
      "vpc_ipv4_ipam_pool_id",
      "vpc_ipv4_netmask_length",
      "vpc_flow_logs",
      "subnets",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.shared_services.subnets
  validation {
    error_message = "For var.central_vpcs.shared_services.subnets, you can only define \"endpoints\", and \"transit_gateway\" subnets."
    condition = length(setsubtract(keys(try(var.central_vpcs.shared_services.subnets, {})), [
      "endpoints",
      "transit_gateway"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.shared_services.subnets.endpoints
  validation {
    error_message = "For Endpoint Subnets in Shared Services VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"nat_gateway_configuration\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.shared_services.subnets.endpoint, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.shared_services.subnets.transit_gateway
  validation {
    error_message = "For TGW Subnets in Shared Services VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.shared_services.subnets.transit_gateway, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }

  # ---------------- VALIDATION OF INGRESS VPC ----------------
  # Valid keys for var.central_vpcs.ingress
  validation {
    error_message = "Only valid key values for the Ingress VPC: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"vpc_flow_logs\", \"subnets\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.ingress, {})), [
      "name",
      "vpc_id",
      "cidr_block",
      "vpc_secondary_cidr",
      "az_count",
      "vpc_enable_dns_hostnames",
      "vpc_enable_dns_support",
      "vpc_instance_tenancy",
      "vpc_ipv4_ipam_pool_id",
      "vpc_ipv4_netmask_length",
      "vpc_flow_logs",
      "subnets",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.ingress.subnets
  validation {
    error_message = "For var.central_vpcs.ingress.subnets, you can only define \"public\", \"private\",  and \"transit_gateway\" subnets."
    condition = length(setsubtract(keys(try(var.central_vpcs.ingress.subnets, {})), [
      "public",
      "private",
      "transit_gateway"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.ingress.subnets.public
  validation {
    error_message = "For Public Subnets in Ingress VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"nat_gateway_configuration\", \"route_to_transit_gateway\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.ingress.subnets.public, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "route_to_transit_gateway",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.ingress.subnets.private
  validation {
    error_message = "For Private Subnets in Ingress VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"nat_gateway_configuration\", \"route_to_transit_gateway\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.ingress.subnets.private, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "route_to_transit_gateway",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.ingress.subnets.transit_gateway
  validation {
    error_message = "For TGW Subnets in Ingress VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.ingress.subnets.transit_gateway, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }

  # ---------------- VALIDATION OF HYBRID DNS VPC ----------------
  # Valid keys for var.central_vpcs.hybrid_dns
  validation {
    error_message = "Only valid key values for the Hybrid DNS VPC: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"vpc_flow_logs\", \"subnets\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.hybrid_dns, {})), [
      "name",
      "vpc_id",
      "cidr_block",
      "vpc_secondary_cidr",
      "az_count",
      "vpc_enable_dns_hostnames",
      "vpc_enable_dns_support",
      "vpc_instance_tenancy",
      "vpc_ipv4_ipam_pool_id",
      "vpc_ipv4_netmask_length",
      "vpc_flow_logs",
      "subnets",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.hybrid_dns.subnets
  validation {
    error_message = "For var.central_vpcs.hybrid_dns.subnets, you can only define \"endpoints\", and \"transit_gateway\" subnets."
    condition = length(setsubtract(keys(try(var.central_vpcs.hybrid_dns.subnets, {})), [
      "endpoints",
      "transit_gateway"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.hybrid_dns.subnets.endpoints
  validation {
    error_message = "For Endpoint Subnets in Hybrid DNS VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"nat_gateway_configuration\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.hybrid_dns.subnets.endpoint, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.hybrid_dns.subnets.transit_gateway
  validation {
    error_message = "For TGW Subnets in Hybrid DNS VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.hybrid_dns.subnets.transit_gateway, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }
}

# Spoke VPCs
variable "spoke_vpcs" {
  description = <<-EOF
  Definition of the Spoke VPCs to include in the Hub and Spoke architecture. It is out of the scope of this module the creation of the Spoke VPCs and their attachments to the Transit Gateway. The module will only handle the VPC attachments and the routing logic in the Transit Gateway.
  **Attributes to define**:
  - `number_spokes`   = (Optional|Int) **If set need to be greater than 0**. The number of Spoke VPCs attached to the Transit Gateway.
  - `cidrs_list`      = (Optional|list(string)) List of the CIDR blocks of all the VPCs attached to the Transit Gateway. The list of CIDR blocks will be used in the Central VPCs to route to the Transit Gateway - in those central VPCs that have already a route to the Internet (0.0.0.0/0). If not specified, no routes will be created and you will need to create them outside this module.
  - `vpc_attachments` = (Optional|list(string)) List of Spoke VPC Transit Gateway attachments. The VPC attachments will be associated to the Spoke TGW Route Table, and propagated to the corresponding Central TGW Route Tables.
EOF
  type        = any

  default = {
    number_spokes = 0
  }

  # ---------------- VALID KEYS FOR var.central_vpcs ----------------
  validation {
    error_message = "Only valid key values for spoke_vpcs: \"supernet\", \"vpc_attachments\"."
    condition = length(setsubtract(keys(var.spoke_vpcs), [
      "number_spokes",
      "cidrs_list",
      "vpc_attachments",
    ])) == 0
  }

  # If the var.spoke_vpcs.number_spokes is defined (> 0), a list of TGW VPC attachments should be defined
  validation {
    error_message = "You should define both var.spoke_vpcs.number_spokes and var.spoke_vpcs.vpc_attachments."
    condition     = (var.spoke_vpcs.number_spokes > 0) && (try(var.spoke_vpcs.vpc_attachments, "empty") != "empty")
  }
}



