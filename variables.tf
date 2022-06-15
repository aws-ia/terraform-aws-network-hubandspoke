# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/variables.tf ---

# AWS Region
variable "aws_region" {
  type        = string
  description = "AWS Region to build the Hub and Spoke."
}

# Module identifier
variable "identifier" {
  type        = string
  description = "String to identify the whole Hub and Spoke Architecture"
}

# AWS Transit Gateway Information
variable "transit_gateway" {
  description = "Information about the Transit Gateway. Either you can specify the ID of a current Transit Gateway you created, or you specify a name and this module will proceed to create it."
  type = object({
    name = optional(string)
    id   = optional(string)
  })

  default = {
    name = "transit_gateway"
  }

  validation {
    condition     = length(setintersection(keys(var.transit_gateway), ["name", "id"])) != 1
    error_message = "You need to define one (only) attribute: name of a new TGW, or ID of a current one."
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

  # ---------------- VALIDATION OF INSPECTION VPC ----------------
  # Valid keys var.central_vpcs.inspection
  validation {
    error_message = "Only valid key values for central_vpcs.inspection: \"name\", \"vpc_id\", \"cidr_block\", \"vpc_secondary_cidr\", \"az_count\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\",  \"vpc_instance_tenancy\",  \"vpc_ipv4_ipam_pool_id\",  \"vpc_ipv4_netmask_length\",  \"vpc_flow_logs\", \"subnets\", \"tags\"."
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
    error_message = "For Inspection Subnets in Inspection VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.inspection.subnets.inspection, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.inspection.subnets.public
  validation {
    error_message = "For TGW Subnets in Inspection VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.inspection.subnets.transit_gateway, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
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
    error_message = "For Public Subnets in Egress VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"nat_gateway_configuration\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.egress.subnets.public, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "nat_gateway_configuration",
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
  # Valid keys var.central_vpcs.shared_services
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
  # Valid keys var.central_vpcs.ingress
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
    error_message = "For Public Subnets in Ingress VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"nat_gateway_configuration\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.ingress.subnets.public, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.ingress.subnets.private
  validation {
    error_message = "For Private Subnets in Ingress VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"nat_gateway_configuration\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.ingress.subnets.private, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
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
  # Valid keys var.central_vpcs.hybrid_dns
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

  # Valid keys for var.central_vpcs.hybrid_dns.subnets
  validation {
    error_message = "For var.central_vpcs.shared_services.subnets, you can only define \"endpoints\", and \"transit_gateway\" subnets."
    condition = length(setsubtract(keys(try(var.central_vpcs.hybrid_dns.subnets, {})), [
      "endpoints",
      "transit_gateway"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.hybrid_dns.subnets.endpoints
  validation {
    error_message = "For Endpoint Subnets in Shared Services VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"nat_gateway_configuration\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.hybrid_dns.subnets.endpoint, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }

  # Valid keys for var.central_vpcs.hybrid_dns.subnets.transit_gateway
  validation {
    error_message = "For TGW Subnets in Shared Services VPC, you can only specify: \"cidrs\", \"netmask\", \"name_prefix\", \"tags\"."
    condition = length(setsubtract(keys(try(var.central_vpcs.hybrid_dns.subnets.transit_gateway, {})), [
      "cidrs",
      "netmask",
      "name_prefix",
      "tags"
    ])) == 0
  }
}



