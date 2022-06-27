<!-- BEGIN_TF_DOCS -->
# AWS Hub and Spoke Architecture with AWS Transit Gateway - Example: Central Inspection

In this example, we are building a Hub and Spoke architecture with centralized traffic inspection (East/West and North/South). The following resources are created using the Hub and Spoke module:

- AWS Transit Gateway.
- Transit Gateway Route Tables (Spokes, and Inspection).
- Inspection VPC, with Internet access.  

Outside of the module, the following resources are created:

- Two Spoke VPCs, which definition can be found in *variables.tf*. The VPCs have VPC Flow Logs enabled, with Amazon CloudWatch Logs as destination.
- AWS Systems Manager VPC endpoints, which definition can be found in *locals.tf*. The module **vpc\_endpoints** creates the VPC endpoints and the Security Groups to apply (as per the definition in *locals.tf*) in each Spoke VPC.
- EC2 instances in all the Spoke VPCs (1 in each Availability Zone defined), and the Security Groups to use by the instances as per defined in *locals.tf*. The module **compute** creates these resources.
- All the IAM roles (the ones needed to publish the VPC Flow Logs in CloudWatch logs) and the KMS Key to encrypt these logs are created in the **iam\_kms** module.

![Architecture diagram](https://github.com/aws-ia/terraform-aws-network-hubandspoke/blob/346b078adc3fc6ace62de2ba216a9ef92666b71b/examples/central_inspection/images/architecture_diagram.png)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.73.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.75.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_compute"></a> [compute](#module\_compute) | ./modules/compute | n/a |
| <a name="module_hub-and-spoke"></a> [hub-and-spoke](#module\_hub-and-spoke) | ../.. | n/a |
| <a name="module_iam_kms"></a> [iam\_kms](#module\_iam\_kms) | ./modules/iam_kms | n/a |
| <a name="module_spoke_vpcs"></a> [spoke\_vpcs](#module\_spoke\_vpcs) | aws-ia/vpc/aws | = 1.4.0 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | ./modules/vpc_endpoints | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_networkfirewall_firewall_policy.anfw_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_rule_group.allow_domains](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.allow_icmp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.drop_remote](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region - to build the Hub and Spoke. | `string` | `"eu-west-1"` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project identifier. | `string` | `"central-inspection"` | no |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | Spoke VPCs to create. | `map(any)` | <pre>{<br>  "spoke-vpc-1": {<br>    "cidr_block": "10.0.0.0/24",<br>    "instance_type": "t2.micro",<br>    "number_azs": 2,<br>    "private_subnets": [<br>      "10.0.0.0/26",<br>      "10.0.0.64/26",<br>      "10.0.0.128/26"<br>    ],<br>    "tgw_subnets": [<br>      "10.0.0.192/28",<br>      "10.0.0.208/28",<br>      "10.0.0.224/28"<br>    ]<br>  },<br>  "spoke-vpc-2": {<br>    "cidr_block": "10.0.1.0/24",<br>    "instance_type": "t2.micro",<br>    "number_azs": 2,<br>    "private_subnets": [<br>      "10.0.1.0/26",<br>      "10.0.1.64/26",<br>      "10.0.1.128/26"<br>    ],<br>    "tgw_subnets": [<br>      "10.0.1.192/28",<br>      "10.0.1.208/28",<br>      "10.0.1.224/28"<br>    ]<br>  }<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_central_vpcs"></a> [central\_vpcs](#output\_central\_vpcs) | Central VPCs created (ID). |
| <a name="output_ec2_instances"></a> [ec2\_instances](#output\_ec2\_instances) | EC2 instances created. |
| <a name="output_network_firewall"></a> [network\_firewall](#output\_network\_firewall) | Network Firewall ID created. |
| <a name="output_spoke_vpcs"></a> [spoke\_vpcs](#output\_spoke\_vpcs) | Spoke VPCs created (ID). |
| <a name="output_tgw_rt_central_vpcs"></a> [tgw\_rt\_central\_vpcs](#output\_tgw\_rt\_central\_vpcs) | Transit Gateway Route Tables associated to Central VPC attachments. |
| <a name="output_tgw_rt_spoke_vpcs"></a> [tgw\_rt\_spoke\_vpcs](#output\_tgw\_rt\_spoke\_vpcs) | Transit Gateway Route Table associated to the Spoke VPC attachments. |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | Transit Gateway ID. |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | SSM VPC endpoints created. |
<!-- END_TF_DOCS -->