---

---

# Example: AWS Hub and Spoke with centralized Endpoints VPC - Logging disabled

This example uses the AWS Hub and Spoke module to create a central endpoints VPC. The resources created by the module are the following ones:

- AWS Transit Gateway, TGW attachments to the Endpoints VPC and Spoke VPCs, and its corresponding TGW Route Tables.
- Endpoints VPC, with centralized VPC endpoints necessary to have AWS Sytems Manager access (ssm, ssmmessages, ec2messages)
- Two Spoke VPCs
- Logging disabled.

The module does not create any EC2 instances, or IAM role - leaving the user the freedom to configure all these resources. For you to have an example on how these resources can be created, you will see code that deploys:

- EC2 instances in the Spoke VPC, and IAM role and Security Group to allow SSM and S3 access.
- Interface VPC endpoint for Amazon S3 access, and a Private Hosted Zone associated to the Spoke VPCs to allow DNS resolution of queries to S3.

![Architecture diagram](./images/architecture_diagram.png)

## Prerequisites

- An AWS account with an IAM user with the appropriate permissions
- Terraform installed

## Code Principles:

- Writing DRY (Do No Repeat Yourself) code using a modular design pattern

## Usage

- Clone the repository
- Edit the variables.tf file in the project root directory. This file contains the variables that are used to configure the VPCs to create, and Hybrid DNS configuration needed to work with your environment.
- To change the configuration about the Security Groups and VPC endpoints to create, edit the locals.tf file in the project root directory
- Initialize Terraform using `terraform init`
- Deploy the template using `terraform apply`

**Note** The default number of Availability Zones to use in the Spoke VPCs is 1. To follow best practices, each resource will be created in each Availability Zone. **Keep this in mind** to avoid extra costs unless you are happy to deploy more resources and accept additional costs.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 3.73.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.73.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_central_endpoints"></a> [central\_endpoints](#module\_central\_endpoints) | ../.. | n/a |
| <a name="module_compute"></a> [compute](#module\_compute) | ./modules/compute | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ./modules/iam | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region to create the environment. | `string` | `"eu-west-1"` | yes |
| <a name="input_cidr_blocks"></a> [cidr\_blocks](#input\_cidr\_blocks) | CIDR blocks to use in the different VPCs to create | `any` | <pre>{<br>  "endpoints_vpc": "10.10.0.0/16",<br>  "spoke_vpcs": {<br>    "spoke_1": "10.0.0.0/16",<br>    "spoke_2": "10.1.0.0/16"<br>  }<br>}</pre> | yes |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project identifier | `string` | `"hub-spoke-endpoints"` | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type to use in the EC2 instances. | `string` | `"t2.micro"` | yes |
| <a name="input_number_azs"></a> [number\_azs](#input\_number\_azs) | Number of AZs - to indicate in all the VPCs created | `number` | `2` | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_instances"></a> [ec2\_instances](#output\_ec2\_instances) | EC2 instances created. |
| <a name="output_endpoints_vpc"></a> [endpoints\_vpc](#output\_endpoints\_vpc) | VPC ID of the Inspection VPC. |
| <a name="output_extra_vpc_endpoint"></a> [extra\_vpc\_endpoint](#output\_extra\_vpc\_endpoint) | S3 VPC Endpoint. |
| <a name="output_spoke_vpcs"></a> [spoke\_vpcs](#output\_spoke\_vpcs) | VPC IDs of the Spoke VPCs. |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | AWS Transit Gateway ID. |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | Interface VPC endpoints created. |
<!-- END_TF_DOCS -->