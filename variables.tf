# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/variables.tf ---

# Module identifier
variable "identifier" {
  type        = string
  description = "String to identify the whole Hub and Spoke environment."
}

# AWS Transit Gateway Information
variable "transit_gateway" {
  description = <<-EOF
  Information about the Transit Gateway. You can specify the ID of a current Transit Gateway you have created, or provide the neccessary information so this module when create a new one. The following attributes can be configured:
  - `id` = (Optional|string) **If you specify this value, no other attributes can be set** Transit Gateway ID, that the module will use as central piece of the Hub and Spoke architecture.
  - `name` = (Optional|string) Name to apply to the new Transit Gateway.
  - `description` = (Optional|string) Description of the Transit Gateway
  - `amazon_side_asn` = (Optional|number) Private Autonomous System Number (ASN) for the Amazon side of a BGP session. The range is `64512` to `65534` for 16-bit ASNs and `4200000000` to `4294967294` for 32-bit ASNs. It is recommended to configure one to avoid ASN overlap. Default value: `64512`.
  - `auto_accept_shared_attachments` = (Optional|string) Wheter the attachment requests are automatically accepted. Valid values: `disable` (default) or `enable`.
  - `dns_support` = (Optional|string) Wheter DNS support is enabled. Valid values: `disable` or `enable` (default).
  - `multicast_support` = (Optional|string) Wheter Multicas support is enabled. Valid values: `disable` (default) or `enable`.
  - `transit_gateway_cidr_blocks` = (Optional|list(string)) One or more IPv4/IPv6 CIDR blocks for the Transit Gateway. Must be a size /24 for IPv4 CIDRs, and /64 for IPv6 CIDRs.
  - `vpn_ecmp_support` = (Optional|string) Whever VPN ECMP support is enabled. Valid values: `disable` or `enable` (default).
  - `tags` = (Optional|map(string)) Key-value tags to apply to the Transit Gateway.
  ```
EOF
  type        = any

  validation {
    error_message = "Only valid key values for var.transit_gateway: \"id\", \"name\", \"description\", \"amazon_side_asn\", \"auto_accept_shared_attachments\", \"dns_support\", \"multicast_support\", \"transit_gateway_cidr_blocks\", \"vpc_ecmp_support\", or \"tags\"."
    condition = length(setsubtract(keys(var.transit_gateway), [
      "id",
      "name",
      "description",
      "amazon_side_asn",
      "auto_accept_shared_attachments",
      "dns_support",
      "multicast_support",
      "transit_gateway_cidr_block",
      "vpn_ecmp_support",
      "tags"
    ])) == 0
  }
}

# Central VPCs
variable "central_vpcs" {
  description = <<-EOF
  Configuration of the Central VPCs - used to centralized different services. You can create the following central VPCs: "inspection", "egress", "shared-services", "hybrid-dns", and "ingress".
  In each Central VPC, You can specify the following attributes:
  - `vpc_id` = (Optional|string) **If you specify this value, no other attributes can be set** VPC ID, the VPC will be attached to the Transit Gateway, and its attachment associate/propagated to the corresponding TGW Route Tables.
  - `cidr_block` = (Optional|string) CIDR range to assign to the VPC if creating a new VPC.
  - `az_count` = (Optional|number) Searches the number of AZs in the region and takes a slice based on this number - the slice is sorted a-z.
  - `vpc_enable_dns_hostnames` = (Optional|bool) Indicates whether the instances launched in the VPC get DNS hostnames. Enabled by default.
  - `vpc_enable_dns_support` = (Optional|bool) Indicates whether the DNS resolution is supported for the VPC. If enabled, queries to the Amazon provided DNS server at the 169.254.169.253 IP address, or the reserved IP address at the base of the VPC network range "plus two" succeed. If disabled, the Amazon provided DNS service in the VPC that resolves public DNS hostnames to IP addresses is not enabled. Enabled by default.
  - `vpc_instance_tenancy` = (Optional|string) The allowed tenancy of instances launched into the VPC.
  - `vpc_flow_logs` = (Optional|object(any)) Configuration of the VPC Flow Logs of the VPC configured. Options: "cloudwatch", "s3", "none".
  - `subnet_configuration` = (Optional|any) Configuration of the subnets to create in the VPC. Depending the type of central VPC to create, the format (subnets to configure) will be different.
  To get more information of the format of the variables, check the section "Central VPCs" in the README.
  ```
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

  #  ---------------- SHARED SERVICES VPC (IF DEFINED) CANNOT HAVE A DNS SUBNET IF HYBRID DNS VPC IS DEFINED ----------------
  validation {
    error_message = "If you create a Shared Services and Hybrid DNS VPC at the same time, the Shared Services VPC cannot have Internet access - remove the definition of public subnet(s)."
    condition     = (contains(keys(try(var.central_vpcs, {})), "hybrid_dns") && !contains(keys(try(var.central_vpcs.shared_services.subnets, {})), "dns")) || !contains(keys(try(var.central_vpcs, {})), "hybrid_dns")
  }

  # ---------------- VALIDATION OF INSPECTION VPC ----------------
  validation {
    error_message = "Only valid key values for var.central_vpcs.inspection: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"inspection_flow\", \"aws_network_firewall\", \"vpc_flow_logs\", \"subnets\", \"tags\"."
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
      "inspection_flow",
      "aws_network_firewall",
      "vpc_flow_logs",
      "subnets",
      "tags"
    ])) == 0
  }

  # Valid values for var.central_vpcs.inspection.inspection_flow
  validation {
    error_message = "Only valid definitions of Inspection Flow in var.central_vpcs.inspection: \"east-west\", \"north-south\", \"all\"."
    condition = contains(
      ["east-west", "north-south", "all"],
      try(var.central_vpcs.inspection.inspection_flow, "all")
    )
  }

  # # Inspection Flow cannot be "north-south" if there's no Egress VPC and the Inspection VPC has only private subnets
  # validation {
  #   error_message = "No Egress VPC and Inspection VPC without public subnets, \"north-south\" inspection is not possible."
  #   condition = 
  # }

  # Valid keys for var.central_vpcs.inspection.aws_network_firewall
  validation {
    error_message = "Only valid key values for var.central_vpcs.inspection.aws_network_firewall: \"name\", \"policy_arn\", \"policy_change_protection\", \"subnet_change_protection\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.inspection.aws_network_firewall, {})), [
      "name",
      "policy_arn",
      "policy_change_protection",
      "subnet_change_protection",
      "tags"
    ])) == 0
  }

  # ---------------- VALIDATION OF EGRESS VPC ----------------
  # Valid keys var.central_vpcs.egress
  validation {
    error_message = "Only valid key values for central_vpcs.egress: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"vpc_flow_logs\", \"subnets\", \"tags\"."
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

  # ---------------- VALIDATION OF SHARED SERVICES VPC ----------------
  validation {
    error_message = "Only valid key values for central_vpcs.shared_services: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"vpc_flow_logs\", \"subnets\", \"tags\"."
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

  # ---------------- VALIDATION OF INGRESS VPC ----------------
  validation {
    error_message = "Only valid key values for central_vpcs.ingress: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"vpc_flow_logs\", \"subnets\", \"tags\"."
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

  # ---------------- VALIDATION OF HYBRID DNS VPC ----------------
  validation {
    error_message = "Only valid key values for central_vpcs.hybrid_dns: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"vpc_flow_logs\", \"subnets\", \"tags\"."
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
}

# Spoke VPCs
variable "spoke_vpcs" {
  description = <<-EOF
  Spoke VPCs information. You can specify the following attributes:
  - `network_cidr_block` = (Optional|string) Network's Supernet CIDR Block. **Note** that either this attribute or `network_prefix_list` has to be defined (but not both).
  - `network_prefix_list` = (Optional|string) Network's Prefix List ID. **Note** that either this attribute or `network_cidr_block` has to be defined (but not both).
  - `vpc_information` = (Optional|map(any)) Information about the Spoke VPCs to add into the Hub and Spoke architecture. This variable expects a map formed by: 
    - First, the segment of that group of VPCs. 
    - Each segment expects a map of VPCs, which will be included in the same segment when creating the routes in the Transit Gateway.
    - Each VPC expects a map with the following attributes: `vpc_id` and `transit_gateway_attachment_id`.
  To get more information of the format of the variables, check the section "Spoke VPCs" in the README.
  ```
EOF
  type        = any

  # Valid keys for var.spoke_vpcs (all the segments defined)
  validation {
    error_message = "Only valid key values for var.spoke_vpcs: \"network_cidr_block\", \"network_prefix_list\", \"vpc_information\"."
    condition = length(setsubtract(keys(var.spoke_vpcs), [
      "network_cidr_block",
      "network_prefix_list",
      "vpc_information"
    ])) == 0
  }

  # Either `network_cidr_block` or `network_prefix_list` should be provided
  validation {
    error_message = "You need to provide either \"network_cidr_block\" or \"network_prefix_list\"."
    condition = length(setintersection(keys(var.spoke_vpcs), [
      "network_cidr_block",
      "network_prefix_list"
    ])) == 1
  }

  # Valid keys for all the items in var.spoke_vpcs.vpc_information
  # validation {
  #   error_message = "Only valid key values for items in each segment inside var.spoke_vpcs.vpc_information: \"vpc_id\", \"transit_gateway_attachment_id\"."
  #   condition = alltrue(
  #     [
  #       for vpc in values( { for k, v in try(var.spoke_vpcs.vpc_information, {}): k => v } ) : length(setsubtract(keys(vpc), [
  #         "vpc_id",
  #         "transit_gateway_attachment_id"
  #       ])) == 0
  #     ]
  #   )
  # }
}