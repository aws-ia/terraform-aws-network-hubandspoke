# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/outputs.tf ---

# AWS TRANSIT GATEWAY (if created)
output "transit_gateway" {
  description = <<-EOF
  AWS Transit Gateway resource. Check the resource in the Terraform Registry - [aws_ec2_transit_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) - for more information about the output attributes.
  ```
EOF
  value       = try(aws_ec2_transit_gateway.tgw[0], null)
}

# CENTRAL VPCS
output "central_vpcs" {
  description = <<-EOF
  Central VPCs created. Check the [AWS VPC Module](https://github.com/aws-ia/terraform-aws-vpc) README for more information about the output attributes.
  ```
EOF
  value       = module.central_vpcs
}

# TRANSIT GATEWAY ROUTE TABLES
output "transit_gateway_route_tables" {
  description = <<-EOF
  Transit Gateway Route Tables. The format of the output is the following one:

  ```hcl
  transit_gateway_route_tables = {
    central_vpcs = {
      inspection = { ... }
      egress = { ... }
      ...
    }
    spoke_vpcs = {
      segment1 = { ... }
      segment2 = { ... }
      ...
    }
  }  
  ```
  Check the AWS Transit Gateway Route Table resource in the Terraform Registry - [aws_ec2_transit_gateway_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) for more information about the output attributes.
  ```
EOF
  value = {
    central_vpcs = aws_ec2_transit_gateway_route_table.tgw_route_table
    spoke_vpcs   = local.vpc_information ? { for k, v in module.spoke_vpcs : k => v.transit_gateway_spoke_rt } : null
  }
}

# AWS NETWORK FIREWALL RESOURCE (IF CREATED)
output "aws_network_firewall" {
  description = <<-EOF
  AWS Network Firewall resource. Check the resource in the Terraform Registry - [aws_networkfirewall_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall) - for more information about the output attributes.
  ```
EOF
  value       = local.create_anfw ? module.aws_network_firewall[0].aws_network_firewall : null
}