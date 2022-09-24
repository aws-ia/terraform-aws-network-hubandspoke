<!-- BEGIN_TF_DOCS -->
# AWS Hub and Spoke Architecture with AWS Transit Gateway - Example: Central Shared Services

This example centralizes VPC endpoints for AWS Systems Manager (so the instances can be accessed using Session Manager), with a central Shared Services VPC. The following resources are built:

- Built by the **Hub and Spoke module**:
  - AWS Transit Gateway Route Tables: 1 Inspection, 3 Spokes (production, development, and testing).
  - Transit Gateway routes.
  - Shared Services VPC.
- Built outside the module:
  - AWS Transit Gateway.
  - 3 VPCs: 1 production, 1 development, and 1 testing.
  - EC2 instances in each Spoke VPC.
  - IAM role used for the EC2 instances to access AWS Systems Manager.
  - SSM VPC endpoints in the Shared Services VPC, and Private Hosted Zones associated to the Spoke VPCs.

If you simply want to review the infrastructure without any workloads, remove/comment the last four modules in the *main.tf* file - remember to also remove/comment the outputs.

## Deployment instructions

* First, you need to deploy the AWS Transit Gateway, and Spoke VPCs - `terraform apply -target="aws_ec2_transit_gateway.tgw" -target="module.spoke_vpcs"`.
* Once the resources are created, you can finish and apply the rest of the resources - `terraform apply`.
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.32.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_compute"></a> [compute](#module\_compute) | ./modules/compute | n/a |
| <a name="module_hub-and-spoke"></a> [hub-and-spoke](#module\_hub-and-spoke) | ../.. | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ./modules/iam | n/a |
| <a name="module_phz"></a> [phz](#module\_phz) | ./modules/phz | n/a |
| <a name="module_spoke_vpcs"></a> [spoke\_vpcs](#module\_spoke\_vpcs) | aws-ia/vpc/aws | = 3.0.0 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | ./modules/vpc_endpoints | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region - to build the Hub and Spoke. | `string` | `"eu-west-2"` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project identifier. | `string` | `"central-shared-services"` | no |
| <a name="input_spoke_vpcs"></a> [spoke\_vpcs](#input\_spoke\_vpcs) | Spoke VPCs definition. | `any` | <pre>{<br>  "dev": {<br>    "az_count": 2,<br>    "cidr_block": "10.1.0.0/24",<br>    "instance_type": "t2.micro",<br>    "private_subnet_netmask": 28,<br>    "tgw_subnet_netmask": 28,<br>    "type": "development"<br>  },<br>  "prod": {<br>    "az_count": 2,<br>    "cidr_block": "10.0.0.0/24",<br>    "instance_type": "t2.micro",<br>    "private_subnet_netmask": 28,<br>    "tgw_subnet_netmask": 28,<br>    "type": "production"<br>  },<br>  "test": {<br>    "az_count": 2,<br>    "cidr_block": "10.2.0.0/24",<br>    "instance_type": "t2.micro",<br>    "private_subnet_netmask": 28,<br>    "tgw_subnet_netmask": 28,<br>    "type": "testing"<br>  }<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_instances"></a> [ec2\_instances](#output\_ec2\_instances) | EC2 instances created. |
| <a name="output_private_hosted_zones"></a> [private\_hosted\_zones](#output\_private\_hosted\_zones) | Private Hosted Zones created. |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | Transit Gateway ID. |
| <a name="output_transit_gateway_route_tables"></a> [transit\_gateway\_route\_tables](#output\_transit\_gateway\_route\_tables) | Transit Gateway Route Tables. |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | SSM VPC endpoints created. |
| <a name="output_vpcs"></a> [vpcs](#output\_vpcs) | VPCs created. |
<!-- END_TF_DOCS -->