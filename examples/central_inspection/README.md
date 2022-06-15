<!-- BEGIN_TF_DOCS -->
# AWS Hub and Spoke Architecture with AWS Transit Gateway - Example: Central Inspection

In this specific example, the following resources are built:

- AWS Transit Gateway - outside of the Hub and Spoke module.
- Created by the module:
  - AWS Transit Gateway Route Tables: Inspection RT (with Internet access), and Spoke RT.
  - VPCs: Inspection VPC.
  - Regarding TGW Route Tables, the Spoke RT will have a 0.0.0.0/0 route to the Inspection VPC, and the Inspection RT will be empty (waiting to have Spoke VPCs to propagate their CIDR blocks)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.73.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.18.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_hub-and-spoke"></a> [hub-and-spoke](#module\_hub-and-spoke) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region - to build the Hub and Spoke. | `string` | `"eu-west-1"` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project identifier. | `string` | `"central-inspection"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_central_vpcs"></a> [central\_vpcs](#output\_central\_vpcs) | Central VPCs created (ID). |
| <a name="output_tgw_rt_central_vpcs"></a> [tgw\_rt\_central\_vpcs](#output\_tgw\_rt\_central\_vpcs) | Transit Gateway Route Tables associated to Central VPC attachments. |
| <a name="output_tgw_rt_spoke_vpcs"></a> [tgw\_rt\_spoke\_vpcs](#output\_tgw\_rt\_spoke\_vpcs) | Transit Gateway Route Table associated to the Spoke VPC attachments. |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | Transit Gateway ID. |
<!-- END_TF_DOCS -->