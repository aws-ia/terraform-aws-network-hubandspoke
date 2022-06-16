<!-- BEGIN_TF_DOCS -->
# AWS Hub and Spoke Architecture with AWS Transit Gateway - Terraform Module

[AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html) is a network hub that you can use to interconnect your VPCs and on-premises networks. With it, you can create hub and spoke architectures to control how your VPCs and on-prem resources communicate between them. In addition, you can centralize different services - like traffic inspection or the connection to VPC endpoints - and therefore avoid extra costs by overprovisioning those services.

This Terraform module helps you create the base of your networking infrastructure in AWS, by provisioning a Hub and Spoke Architecture with AWS Transit Gateway. You can indicate which resources you want to centralize - by defining which central VPCs you want to create -, and you get the Transit Gateway, VPCs, and routing needed to achieve the interconnection. The only thing you will need to do later is place your worloads and services to centralize.

## Architecture

![Architecture diagram](https://github.com/aws-ia/terraform-aws-network-hubandspoke/blob/346b078adc3fc6ace62de2ba216a9ef92666b71b/images/architecture_diagram.png)

## Usage

By default, the AWS Transit Gateway is the only resource it will be created - no VPCs are created without explicitly defining it. By checking the input variables, you will see that there is one variable (*object*) to define all the central VPCs - you can check below the input format to define the Central VPCs, and the differences between them when defining the subnets.

Note that the services to place in the VPCs (firewall endpoints, VPC endpoints, instances, etc.) are not created, leaving you the freedom to place whatever you want once the infrastructure is created. Same about IAM roles or KMS Keys, if you want to enable logging in the VPCs created, you will need to create these resources first and provide the ID/ARN in the module variables. The exceptions are NAT gateways (if egress traffic is selected) and SSM endpoints (created either centralized in the Endpoints VPC or decentralized in all the Spoke VPCs).

### Central VPCs

The Central VPCs you can create are: `inspection`, `egress`, `ingress`, `shared_services`, and `hybrid_dns`. The Central VPCs you define have a set of input variables that are common (regardless of the type of VPC to create). These variables are inherited from the [AWS VPC Module](https://github.com/aws-ia/terraform-aws-vpc), which is used to create all the VPCs in this module. The common attributes are the following ones:

- `vpc_id` (Optional|string) **If you specify this value, no other attributes can be set** The VPC will be attached to the Transit Gateway, and its attachment associate/propagated to the corresponding TGW Route Tables.
- `name` (Optional|string) Name of the VPC, if a new VPC is created.
- `cidr_block` (Optional|string) CIDR range to assign to the VPC, if a new VPC is created.
- `az_count` (Optional|number) Number of Availability Zones to use in each VPC. As best practice, we recommend the use of at least two AZs to ensure high-availability in your solutions.
- `vpc_enable_dns_hostnames` (Optional|bool) Indicates whether the instances launched in the VPC get DNS hostnames. **Enabled by default**.
- `vpc_enable_dns_support` (Optional|bool) Indicates whether the DNS resolution is supported for the VPC. If enabled, queries to the Amazon provided DNS server at the 169.254.169.253 IP address, or the reserved IP address at the base of the VPC network range "plus two" succeed. If disabled, the Amazon provided DNS service in the VPC that resolves public DNS hostnames to IP addresses is not enabled. **Enabled by default**.
- `vpc_instance_tenancy` (Optional|string) The allowed tenancy of instances launched into the VPC.
- `vpc_flow_logs` = (Optional|object(any)) Configuration of the VPC Flow Logs of the VPC configured. Options: "cloudwatch", "s3", "none". The format of the object to define is the following:

```hcl
object({
    log_destination = optional(string)
    iam_role_arn    = optional(string)
    kms_key_id      = optional(string)

    log_destination_type = string
    retention_in_days    = optional(number)
    tags                 = optional(map(string))
    traffic_type         = optional(string)
    destination_options = optional(object({
      file_format                = optional(string)
      hive_compatible_partitions = optional(bool)
      per_hour_partition         = optional(bool)
    }))
  })
```

- `subnet_configuration` (Optional|any) Configuration of the subnets to create in the VPC. Depending the type of Central VPC to create, the format (subnets to configure) will be different.
  - **Inspection VPC**: you can create `public`, `private`, and `transit_gateway` subnets. All these subnets accept the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. Aside that:
    - The public subnets also accept the attribute `nat_gateway_configuration`, to indicate if the NAT gateways should be created by the module (or if you want to create them separately). You can specify `all_azs`, `single_az`, or `none`.
    - You cannot specify at the same time `cidrs` and `netmask` - only one of them is allowed.
    - The creation of public subnets is optional.
    - **NOTE** Both Inspection VPC with public subnets and Egress VPC cannot be created at the same time.
  - **Egress VPC**: you can create `public`, and `transit_gateway` subnets. All these subnets accept the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. Aside that:
    - The public subnets also accept the attribute `nat_gateway_configuration`, to indicate if the NAT gateways should be created by the module (or if you want to create them separately). You can specify `all_azs`, `single_az`, or `none`.
    - **NOTE** Both Inspection VPC with public subnets and Egress VPC cannot be created at the same time.
  - **Shared Services VPC**: you can create `endpoints`, and `transit_gateway` subnets. All these subnets accept the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`.
  - **Hybrid DNS VPC**: you can create `endpoints`, and `transit_gateway` subnets. All these subnets accept the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`.
  - **Ingress VPC**: you can create `public`, `private`, and `transit_gateway` subnets. All these subnets accept the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. Aside that, the creation of private subnets is optional.

#### Example: Defining Inspection VPC (with Internet access) and Shared Services VPC

```hcl
central_vpcs = {

    inspection = {
        name = "inspection-vpc"
        cidr_block = "10.10.0.0/16"
        az_count = 2

        subnets = {
            public = {
                netmask = 24
                nat_gateway_configuration = "all_azs"
            }
            inspection = {
                netmask = 24
            }
            transit_gateway = {
                netmask = 28
            }
        }
    }

    shared_services = {
        name = "shared-services-vpc"
        cidr_block = "10.20.0.0/16"
        az_count = 2

        subnets = {
            endpoints = {
                cidrs = ["10.20.0.0/24", "10.20.1.0/24"]
                name_prefix = "vpc-endpoints"
            }
            transit_gateway = {
                cidrs = ["10.20.2.0/28", "10.20.2.16/28"]
                name_prefix = "transit_gateway"
            }
        }
    }
}
```

#### Example: Defining Egress VPC with more specific input variables

```hcl
central_vpcs = {

    egress = {
        name = "egress-vpc"
        cidr_block = "10.10.0.0/16"
        az_count = 2
        vpc_enable_dns_hostnames = true
        vpc_enable_dns_support = true
        vpc_instance_tenancy = "default"

        vpc_flow_logs = {
            iam_role_arn = "ROLEARN" # You should add here an IAM role so VPC Flow logs can publish in CloudWatch Logs
            kms_key_id = "KMSARN" # You should add here a KMS Key ARN to encrypt the logs at rest (best practice)

            log_destination_type = "cloudwatch"
            retention_in_days = 7
        }

        subnets = {
            public = {
                name_prefix = "public_egress"
                cidrs = ["10.0.0.0/24", "10.0.1.0/24"]
                nat_gateway_configuration = "all_azs"
            }
            transit_gateway = {
                name_prefixt = "tgw_egress"
                cidrs = ["10.0.2.0/28", "10.0.2.16/28"]
            }
        }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.73.0, < 4.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.73.0, < 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_central_vpcs"></a> [central\_vpcs](#module\_central\_vpcs) | aws-ia/vpc/aws | == 1.4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway_route.egress_to_inspection_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.ingress_to_inspection_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.inspection_to_egress_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.spokes_static_default_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route_table.spokes_tgw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table.tgw_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table_association.tgw_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.hybrid_dns_to_spokes_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.shared_services_to_spokes_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_central_vpcs"></a> [central\_vpcs](#input\_central\_vpcs) | Configuration of the Central VPCs - used to centralized different services. You can create the following central VPCs: "inspection", "egress", "shared-services", "hybrid-dns", and "ingress".<br>In each Central VPC, You can specify the following attributes:<br>- `vpc_id` = (Optional\|string) **If you specify this value, no other attributes can be set** VPC ID, the VPC will be attached to the Transit Gateway, and its attachment associate/propagated to the corresponding TGW Route Tables.<br>- `cidr_block` = (Optional\|string) CIDR range to assign to the VPC if creating a new VPC.<br>- `az_count` = (Optional\|number) Searches the number of AZs in the region and takes a slice based on this number - the slice is sorted a-z.<br>- `vpc_enable_dns_hostnames` = (Optional\|bool) Indicates whether the instances launched in the VPC get DNS hostnames. Enabled by default.<br>- `vpc_enable_dns_support` = (Optional\|bool) Indicates whether the DNS resolution is supported for the VPC. If enabled, queries to the Amazon provided DNS server at the 169.254.169.253 IP address, or the reserved IP address at the base of the VPC network range "plus two" succeed. If disabled, the Amazon provided DNS service in the VPC that resolves public DNS hostnames to IP addresses is not enabled. Enabled by default.<br>- `vpc_instance_tenancy` = (Optional\|string) The allowed tenancy of instances launched into the VPC.<br>- `vpc_flow_logs` = (Optional\|object(any)) Configuration of the VPC Flow Logs of the VPC configured. Options: "cloudwatch", "s3", "none".<br>- `subnet_configuration` = (Optional\|any) Configuration of the subnets to create in the VPC. Depending the type of central VPC to create, the format (subnets to configure) will be different.<br>To get more information of the format of the variables, check the section "Central VPCs" in the README.<pre></pre> | `any` | n/a | yes |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | String to identify the whole Hub and Spoke Architecture | `string` | n/a | yes |
| <a name="input_transit_gateway"></a> [transit\_gateway](#input\_transit\_gateway) | Information about the Transit Gateway. Either you can specify the ID of a current Transit Gateway you created, or you specify a name and this module will proceed to create it. | <pre>object({<br>    name = optional(string)<br>    id   = optional(string)<br>  })</pre> | <pre>{<br>  "name": "transit_gateway"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_central_vpcs"></a> [central\_vpcs](#output\_central\_vpcs) | Central VPCs created. |
| <a name="output_tgw_rt_central_vpcs"></a> [tgw\_rt\_central\_vpcs](#output\_tgw\_rt\_central\_vpcs) | Transit Gateway Route Tables associated to the Central VPC attachments. |
| <a name="output_tgw_rt_spoke_vpc"></a> [tgw\_rt\_spoke\_vpc](#output\_tgw\_rt\_spoke\_vpc) | Transit Gateway Route Table associated to the Spoke VPCs. |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | AWS Transit Gateway. |
<!-- END_TF_DOCS -->