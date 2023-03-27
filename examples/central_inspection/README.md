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
  - AWS Network Firewall policy and rule groups - check the *policy.tf* file.

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
| [aws_networkfirewall_firewall_policy.anfw_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_rule_group.allow_domains](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.drop_remote](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region - to build the Hub and Spoke. | `string` | `"eu-west-1"` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project identifier. | `string` | `"central-inspection"` | no |
| <a name="input_spoke_vpcs"></a> [spoke\_vpcs](#input\_spoke\_vpcs) | Spoke VPCs. | `map(any)` | <pre>{<br>  "nonprod-vpc": {<br>    "cidr_block": "10.0.1.0/24",<br>    "number_azs": 2,<br>    "routing_domain": "nonprod"<br>  },<br>  "prod-vpc": {<br>    "cidr_block": "10.0.0.0/24",<br>    "number_azs": 2,<br>    "routing_domain": "prod"<br>  }<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_central_vpcs"></a> [central\_vpcs](#output\_central\_vpcs) | Central VPCs created. |
| <a name="output_network_firewall"></a> [network\_firewall](#output\_network\_firewall) | AWS Network Firewall ID. |
| <a name="output_spoke_vpcs"></a> [spoke\_vpcs](#output\_spoke\_vpcs) | Spoke VPCs created. |
| <a name="output_transit_gateway_id"></a> [transit\_gateway\_id](#output\_transit\_gateway\_id) | ID of the AWS Transit Gateway resource. |
<!-- END_TF_DOCS -->