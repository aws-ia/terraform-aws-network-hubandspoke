<!-- BEGIN_TF_DOCS -->
# AWS Hub and Spoke Architecture with AWS Transit Gateway - Example: Central Egress and Ingress VPCs

This example builds a central Ingress and Egress VPCs. The following resources are built:

- Built by the **Hub and Spoke module**:
  - AWS Transit Gateway Route Tables: 1 Ingress, 1 Egress, 1 Spokes.
  - Transit Gateway routes.
  - Ingress and Egress VPC.
- Built outside the module:
  - AWS Transit Gateway.
  - Managed Prefix List

## Deployment instructions

* To apply all the resources - `terraform apply`.
* Once you finish your testing remember to delete the resources to avoid having unexpected charges - `terraform destroy`.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.73.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.73.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_hub-and-spoke"></a> [hub-and-spoke](#module\_hub-and-spoke) | aws-ia/network-hubandspoke/aws | 3.0.0 |
| <a name="module_spoke_vpcs"></a> [spoke\_vpcs](#module\_spoke\_vpcs) | aws-ia/vpc/aws | 4.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_managed_prefix_list.network_prefix_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list) | resource |
| [aws_ec2_transit_gateway.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region - to build the Hub and Spoke. | `string` | `"eu-west-1"` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project identifier. | `string` | `"central-egress-ingress"` | no |
| <a name="input_spoke_vpcs"></a> [spoke\_vpcs](#input\_spoke\_vpcs) | Spoke VPCs. | `map(any)` | <pre>{<br>  "vpc1": {<br>    "cidr_block": "10.0.0.0/24",<br>    "number_azs": 2,<br>    "routing_domain": "prod"<br>  },<br>  "vpc2": {<br>    "cidr_block": "10.0.1.0/24",<br>    "number_azs": 2,<br>    "routing_domain": "prod"<br>  }<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_central_vpcs"></a> [central\_vpcs](#output\_central\_vpcs) | Central VPCs created. |
| <a name="output_spoke_vpcs"></a> [spoke\_vpcs](#output\_spoke\_vpcs) | Spoke VPCs created. |
| <a name="output_transit_gateway_id"></a> [transit\_gateway\_id](#output\_transit\_gateway\_id) | ID of the AWS Transit Gateway resource. |
<!-- END_TF_DOCS -->