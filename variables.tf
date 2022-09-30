# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/variables.tf ---

# Module identifier
variable "identifier" {
  type        = string
  description = "String to identify the whole Hub and Spoke environment."
}

# AWS Transit Gateway Information
variable "transit_gateway_id" {
  type        = string
  description = "Transit Gateway ID. **If you specify this value, transit_gateway_attributes can't be set**."
  default     = null
}

variable "transit_gateway_attributes" {
  description = <<-EOF
  Attributes about the new Transit Gateway to create. **If you specify this value, transit_gateway_id can't be set**:
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
  default     = {}

  validation {
    error_message = "Only valid key values for var.transit_gateway: \"name\", \"description\", \"amazon_side_asn\", \"auto_accept_shared_attachments\", \"dns_support\", \"multicast_support\", \"transit_gateway_cidr_blocks\", \"vpc_ecmp_support\", or \"tags\"."
    condition = length(setsubtract(keys(var.transit_gateway_attributes), [
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

# Network IPv4 CIDR configuration
variable "network_definition" {
  type = object({
    type  = string
    value = string
  })
  description = <<-EOF
  "Definition of the IPv4 CIDR configuration. The definition is done by using two variables:"
    - `type` = (string) Defines the type of network definition provided. It has to be either `CIDR` (Supernet's CIDR Block) or `PREFIX_LIST` (prefix list ID containing all the CIDR blocks of the network)
    - `value` = (string) Either a Supernet's CIDR Block or a prefix list ID. This value needs to be consistent with the `type` provided in this variable.
  ```
EOF

  # Variable var.network_definition.type can only be 'CIDR' or 'PREFIX_LIST'
  validation {
    condition     = var.network_definition.type == "CIDR" || var.network_definition.type == "PREFIX_LIST"
    error_message = "Invalid input in var.network_definition.type, options: \"CIDR\", or \"PREFIX_LIST\"."
  }
}

# Spoke VPCs
variable "spoke_vpcs" {
  description = <<-EOF
  Variable is used to provide the Hub and Spoke module the neccessary information about the Spoke VPCs created. Within this variable, a map of routing domains is expected. The *key* of each map will defined that specific routing domain (e.g. prod, nonprod, etc.) and a Transit Gateway Route Table for that routing domain will be created. Inside each routing domain definition, you can define a map of VPCs with the following attributes:
    - `vpc_id` = (Optional|string) VPC ID. *This value is not used in this version of the module, we keep it as placehoder when adding support for centralized VPC endpoints*.
    - `transit_gateway_attachment_id` = (Optional|string) Transit Gateway VPC attachment ID.
  To get more information of the format of the variables, check the section "Spoke VPCs" in the README.
  ```
EOF
  type        = any
  default     = {}
}
