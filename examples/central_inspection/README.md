<!-- BEGIN_TF_DOCS -->
# AWS Hub and Spoke Architecture with AWS Transit Gateway - Example: Central Inspection

This example centralizes the traffic inspection and egress traffic within the same VPC, with a central Inspection VPC with public subnets. The following resources are built:

- Built by the **Hub and Spoke module**:
  - AWS Transit Gateway.
  - AWS Transit Gateway Route Tables: 1 Inspection, 2 Spokes (production and non-production).
  - Transit Gateway routes.
  - Inspection VPC - with public subnets for Internet access.
  - AWS Network Firewall (and routes in the Inspection VPC to the firewall endpoints).
- Built outside the module:
  - 3 VPCs: 2 production, and 1 non-production.
  - AWS Network Firewall policy and rule groups - check the *policy.tf* file.
  - EC2 instances, and VPC endpoints in each Spoke VPC.
  - IAM role used for the EC2 instances to access AWS Systems Manager.

If you simply want to review the infrastructure without any workloads, remove/comment the last three modules in the *main.tf* file - remember to also remove/comment the outputs.

## Deployment instructions

* First, you need to deploy the AWS Transit Gateway and the Managed Prefix List. When creating the VPCs (both Spoke and Central ones), Terraform needs those resources created beforehand - `terraform apply -target="module.hub-and-spoke.aws_ec2_transit_gateway.tgw" -target="aws_ec2_managed_prefix_list.network_prefix_list"`
* Once the resources are created, you need to create the Spoke VPCs. When creating the **Hub and Spoke module**, Terraform needs the VPC attachments created beforehand - `terraform apply -target="module.spoke_vpcs"`.
* Now, you can finish and apply the rest of the resources - `terraform apply`.
* Once you finish your testing remember to delete the resources to avoid having unexpected charges - `terraform destroy`.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.73.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.28.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_compute"></a> [compute](#module\_compute) | ./modules/compute | n/a |
| <a name="module_hub-and-spoke"></a> [hub-and-spoke](#module\_hub-and-spoke) | ../.. | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ./modules/iam | n/a |
| <a name="module_spoke_vpcs"></a> [spoke\_vpcs](#module\_spoke\_vpcs) | aws-ia/vpc/aws | = 2.5.0 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | ./modules/vpc_endpoints | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_managed_prefix_list.network_prefix_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list) | resource |
| [aws_ec2_managed_prefix_list_entry.entry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list_entry) | resource |
| [aws_networkfirewall_firewall_policy.anfw_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_rule_group.allow_domains](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.drop_remote](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region - to build the Hub and Spoke. | `string` | `"eu-west-1"` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project identifier. | `string` | `"central-inspection"` | no |
| <a name="input_spoke_vpcs"></a> [spoke\_vpcs](#input\_spoke\_vpcs) | Spoke VPCs definition. | `any` | <pre>{<br>  "nonprod1": {<br>    "az_count": 2,<br>    "cidr_block": "10.1.0.0/24",<br>    "endpoints_subnet_netmask": 28,<br>    "instance_type": "t2.micro",<br>    "private_subnet_netmask": 28,<br>    "tgw_subnet_netmask": 28,<br>    "type": "nonproduction"<br>  },<br>  "prod1": {<br>    "az_count": 2,<br>    "cidr_block": "10.0.0.0/24",<br>    "endpoints_subnet_netmask": 28,<br>    "instance_type": "t2.micro",<br>    "private_subnet_netmask": 28,<br>    "tgw_subnet_netmask": 28,<br>    "type": "production"<br>  },<br>  "prod2": {<br>    "az_count": 2,<br>    "cidr_block": "10.0.1.0/24",<br>    "endpoints_subnet_netmask": 28,<br>    "instance_type": "t2.micro",<br>    "private_subnet_netmask": 28,<br>    "tgw_subnet_netmask": 28,<br>    "type": "production"<br>  }<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_instances"></a> [ec2\_instances](#output\_ec2\_instances) | EC2 instances created. |
| <a name="output_network_firewall"></a> [network\_firewall](#output\_network\_firewall) | AWS Network Firewall ID. |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | Transit Gateway ID. |
| <a name="output_transit_gateway_route_tables"></a> [transit\_gateway\_route\_tables](#output\_transit\_gateway\_route\_tables) | Transit Gateway Route Tables. |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | SSM VPC endpoints created. |
| <a name="output_vpcs"></a> [vpcs](#output\_vpcs) | VPCs created. |
<!-- END_TF_DOCS -->