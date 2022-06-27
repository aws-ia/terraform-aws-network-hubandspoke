<!-- BEGIN_TF_DOCS -->
# AWS Hub and Spoke Architecture with AWS Transit Gateway - Terraform Module

[AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html) is a network hub that you can use to interconnect your VPCs and on-premises networks. With it, you can create hub and spoke architectures to control how your VPCs and on-prem resources communicate between them. In addition, you can centralize different services - like traffic inspection or the connection to VPC endpoints - and therefore avoid extra costs by overprovisioning those services.

This Terraform module helps you create the base of your networking infrastructure in AWS, by provisioning a Hub and Spoke Architecture with AWS Transit Gateway. You can indicate which resources you want to centralize - by defining which central VPCs you want to create -, and you get the Transit Gateway, VPCs, and routing needed to achieve the interconnection. The only thing you will need to do later is place your worloads and services to centralize.

## Architecture

<p align="center">
  <img src="https://raw.githubusercontent.com/aws-ia/terraform-aws-network-hubandspoke/main/images/architecture_diagram.png" alt="Simple" width="100%">
</p>

## Usage

By default, the AWS Transit Gateway is the only resource it will be created - no VPCs are created without explicitly defining it. By checking the input variables, you will see that there are 4 different variables to define:

- `identifier` = (Required|string) To identify the whole Hub and Spoke Architecture. This value is used in several resources for two reasons: to identify which one were created by the module, and to ensure different names when other similar resources are created outside the module.

- `transit_gateway` = (Required|any) Transit Gateway configuration. You specify either the `id` of a current Transit Gateway you created (and the module will use it for all the routing), or the `configuration` variables to create a new one. The following parameters are accepted when configuring a new Transit Gateway:
    - `name`                           = (Optional|String) Name of the new Transit Gateway to create.
    - `amazon_side_asn`                = (Optional|Int) Private Autonomous System Number (ASN) for the Amazon side of a BGP session. The range is `64512` to `65534` for 16-bit ASNs and `4200000000` to `4294967294` for 32-bit ASNs. Default value: `64512`.
    - `auto_accept_shared_attachments` = (Optional|String) Whether resource attachment requests are automatically accepted. Valid values: `disable`, `enable`. Default value: `disable`.
    - `dns_support`                    = (Optional|String) Whether DNS support is enabled. Valid values: `disable`, `enable`. Default value: `enable`.
    - `vpn_ecmp_support`               = (Optional|String) Whether VPN Equal Cost Multipath Protocol support is enabled. Valid values: `disable`, `enable`. Default value: `enable`.
    - `resource_share`                 = (Optional|Bool) Whether the Transit Gateway is shared via Resource Access Manager or not. Valid values: `false`, `true`. Default value: `false`.
    - `tags`                           = (Optional|map(string)) Tags to apply to the Transit Gateway.

- `central_vpcs`= (Optional|any) To configure all the Central VPCs - used to centralized different services. You can create the following Central VPCs:
    - `inspection`      = To centralize the traffic inspection. If created, all the traffic between Spoke VPCs (East/West) and to the Internet (North/South) will be passed to this VPC. You can create Internet access in this VPC, if no Egress VPC is created.
    - `egress`          = To centralize Internet access. You cannot create an Egress VPC and an Inspection VPC with Internet access at the same time.
    - `shared_services` = To centralize VPC endpoint access. This VPC won't have Internet access, and its TGW attachment will be propaged directly to the Spoke TGW Route Table directly.
    - `ingress`         = To centralize ingress access to resources from a central VPC - no distributed Internet access.
    - `hybrid_dns`      = To centralize Hybrid DNS configuration (Route 53 Resolver endpoints or a 3rd-party solution) outside of the Shared Services VPC. This VPC won't have Internet access, and its TGW attachment will be propaged directly to the Spoke TGW Route Table directly.  

You can check below the input format to define the different Central VPCs, and the differences between them when defining its subnets. Note that the services to place in the VPCs (firewall endpoints, VPC endpoints, instances, etc.) are not created, leaving you the freedom to place whatever you want once the infrastructure is created. Same about IAM roles or KMS Keys, if you want to enable logging in the VPCs created, you will need to create these resources first and provide the ID/ARN in the module variables.

- `spoke_vpcs` = (Optional|any) It is out of the scope of this module the creation of the Spoke VPCs - from the subnet/routing definition to the attachment to the Transit Gateway. We recommend the use of the following [AWS VPC Module](https://registry.terraform.io/modules/aws-ia/vpc/aws/latest) to simplify the creation of the VPCs, and the attachments to the Transit Gateway. However, to configure all the Transit Gateway routing (and also the VPC routing of the Central VPCs), the following attributes from the Spoke VPCs can be defined:
    - `number_spokes`   = (Optional|Int) **If set need to be greater than 0**. The number of Spoke VPCs attached to the Transit Gateway.
    - `cidrs_list`      = (Optional|list(string)) List of the CIDR blocks of all the VPCs attached to the Transit Gateway. The list of CIDR blocks will be used in the Central VPCs to route to the Transit Gateway - in those VPCs that have already a route to the Internet (0.0.0.0/0). If not specified, no routes will be created and you will need to create them outside this module.
    - `vpc_attachments` = (Optional|list(string)) List of Spoke VPC Transit Gateway attachments. The VPC attachments will be associated to the Spoke TGW Route Table, and propagated to the corresponding Central TGW Route Tables.

### Central VPCs

The Central VPCs you can create are: `inspection`, `egress`, `ingress`, `shared_services`, and `hybrid_dns`. The Central VPCs you define have a set of input variables that are common (regardless of the type of VPC to create). These variables are inherited from the [AWS VPC Module](https://registry.terraform.io/modules/aws-ia/vpc/aws/latest), which is used to create all the VPCs in this module. The common attributes are the following ones:

- `vpc_id`                   = (Optional|string) **If you specify this value, no other attributes can be set** The VPC will be attached to the Transit Gateway, and its attachment associate/propagated to the corresponding TGW Route Tables.
- `name`                     = (Optional|string) Name of the VPC, if a new VPC is created.
- `cidr_block`               = (Optional|string) CIDR range to assign to the VPC, if a new VPC is created.
- `az_count`                 = (Optional|number) Number of Availability Zones to use in each VPC. As best practice, we recommend the use of at least two AZs to ensure high-availability in your solutions.
- `vpc_enable_dns_hostnames` = (Optional|bool) Indicates whether the instances launched in the VPC get DNS hostnames. **Enabled by default**.
- `vpc_enable_dns_support`   = (Optional|bool) Indicates whether the DNS resolution is supported for the VPC. If enabled, queries to the Amazon provided DNS server at the 169.254.169.253 IP address, or the reserved IP address at the base of the VPC network range "plus two" succeed. If disabled, the Amazon provided DNS service in the VPC that resolves public DNS hostnames to IP addresses is not enabled. **Enabled by default**.
- `vpc_instance_tenancy`     = (Optional|string) The allowed tenancy of instances launched into the VPC.
- `vpc_flow_logs`            = (Optional|object(any)) Configuration of the VPC Flow Logs of the VPC configured. Options: "cloudwatch", "s3", "none". The format of the object to define is the following:

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

- `subnets`                  = (Optional|any) Configuration of the subnets to create in the VPC. Depending the type of Central VPC to create, the format (subnets to configure) will be different.

Check the different subsections below to see the extra variables you can define in each Central VPC.

#### Inspection VPC

You can create `public`, `inspection`, and `transit_gateway` subnets. All of them accept the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. Aside that:

- The public subnets also accept the attribute `nat_gateway_configuration`, to indicate if the NAT gateways should be created by the module (or if you want to create them separately). You can specify `all_azs`, `single_az`, or `none`.
- You cannot specify at the same time `cidrs` and `netmask` - only one of them is allowed.
- The creation of public subnets is optional.
- **NOTE** Both Inspection VPC with public subnets and Egress VPC cannot be created at the same time.

In addition, there's one specific input variable that can be defined in the Inspection VPC: `aws_network_firewall`. This variable will create an AWS Network Firewall resource alongside all the routes in the Inspection VPC. The following attributes are accepted inside this variable:

- `name`                              = (Required|String) Name of the AWS Network Firewall resource.
- `firewall_policy`                   = (Required|String) ARN of the `aws_networkfirewall_firewall_policy` that defines all the firewall polices for the Network Firewall resource.
- `firewall_policy_change_protection` = (Optional|Bool) A boolean flag indicating whether it is possible to change the associated firewall policy. Defaults to `false`.
- `subnet_change_protection`          = (Optional|Bool) A boolean flag indicating whether it is possible to change the associated subnet(s). Defaults to `false`.
- `tags`                              = (Optional|map(any)) Map of resource tags to associate with the resource.

Example definition of an Inspection VPC:

```hcl
central_vpcs = {
    inspection = {
      name       = "inspection-vpc"
      cidr_block = "10.10.0.0/16"
      az_count   = 2

      subnets = {
        public = {
          name_prefix = "public-inspection"
          netmask     = 28
        }
        inspection = {
          name_prefix = "inspection"
          netmask     = 28
        }
        transit_gateway = {
          name_prefix = "tgw-inspection"
          netmask     = 28
        }
      }

      vpc_flow_logs = {
        iam_role_arn = aws_iam_instance_profile.ec2_instance_profile.id
        kms_key_arn  = aws_kms_key.log_key.arn

        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }

      aws_network_firewall = {
        name            = "anfw"
        firewall_policy = aws_networkfirewall_firewall_policy.anfw_policy.arn
      }
    }
  }
```

#### Egress VPC

You can create `public`, and `transit_gateway` subnets. All these subnets accept the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. Aside that:

- The public subnets also accept the attribute `nat_gateway_configuration`, to indicate if the NAT gateways should be created by the module (or if you want to create them separately). You can specify `all_azs`, `single_az`, or `none`.
- **NOTE** Both Inspection VPC with public subnets and Egress VPC cannot be created at the same time.

Example definition of an Egress VPC:

```hcl
central_vpcs = {
    egress = {
      name       = "inspection-vpc"
      cidr_block = "10.20.0.0/16"
      az_count   = 2

      subnets = {
        public = {
          name_prefix = "public-egress"
          netmask     = 28
        }
        transit_gateway = {
          name_prefix = "tgw-egress"
          netmask     = 28
        }
      }

      vpc_flow_logs = {
        iam_role_arn = aws_iam_instance_profile.ec2_instance_profile.id
        kms_key_arn  = aws_kms_key.log_key.arn

        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
    }
  }
```

#### Shared Services VPC

You can create `endpoints`, and `transit_gateway` subnets. All these subnets accept the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`.

Example definition of a Shared Services VPC:

```hcl
central_vpcs = {
    shared_services = {
      name       = "shared-services-vpc"
      cidr_block = "10.30.0.0/16"
      az_count   = 2

      subnets = {
        endpoints = {
          name_prefix = "public-shared-services"
          cidrs       = ["10.30.0.0/24", "10.30.1.0/24"]
        }
        transit_gateway = {
          name_prefix = "tgw-shared_services"
          netmask     = ["10.30.2.0/28", "10.30.2.16/28"]
        }
      }

      vpc_flow_logs = {
        iam_role_arn = aws_iam_instance_profile.ec2_instance_profile.id
        kms_key_arn  = aws_kms_key.log_key.arn

        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
    }
  }
```

#### Hybrid DNS VPC

You can create `endpoints`, and `transit_gateway` subnets. All these subnets accept the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`.

Example definition of a Hybrid DNS VPC:

```hcl
central_vpcs = {
    hybrid_dns = {
      name       = "hybrid-dns-vpc"
      cidr_block = "10.40.0.0/16"
      az_count   = 2

      subnets = {
        endpoints = {
          name_prefix = "public-hybrid-dns"
          cidrs       = ["10.40.0.0/24", "10.40.1.0/24"]
        }
        transit_gateway = {
          name_prefix = "tgw-hybrid-dns"
          netmask     = ["10.40.2.0/28", "10.40.2.16/28"]
        }
      }

      vpc_flow_logs = {
        iam_role_arn = aws_iam_instance_profile.ec2_instance_profile.id
        kms_key_arn  = aws_kms_key.log_key.arn

        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
    }
  }
```

#### Ingress VPC

You can create `public`, `private`, and `transit_gateway` subnets. All these subnets accept the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. Aside that, the creation of private subnets is optional.

Example definition of an Ingress VPC:

```hcl
central_vpcs = {
    hybrid_dns = {
      name       = "ingress-vpc"
      cidr_block = "10.50.0.0/16"
      az_count   = 2

      subnets = {
        public = {
          name_prefix = "public-ingress"
          cidrs       = ["10.50.0.0/24", "10.50.1.0/24"]
        }
        private = {
          name_prefix = "private-ingress"
          cidrs       = ["10.50.2.0/24", "10.50.3.0/24"]
        }
        transit_gateway = {
          name_prefix = "tgw-ingress"
          netmask     = ["10.50.4.0/28", "10.50.4.16/28"]
        }
      }

      vpc_flow_logs = {
        iam_role_arn = aws_iam_instance_profile.ec2_instance_profile.id
        kms_key_arn  = aws_kms_key.log_key.arn

        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
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
| <a name="module_aws_network_firewall"></a> [aws\_network\_firewall](#module\_aws\_network\_firewall) | ./modules/aws_network_firewall | n/a |
| <a name="module_central_vpcs"></a> [central\_vpcs](#module\_central\_vpcs) | aws-ia/vpc/aws | = 1.4.0 |

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
| [aws_ec2_transit_gateway_route_table_association.spokes_tgw_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway_route_table_association.tgw_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.hybrid_dns_to_spokes_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.shared_services_to_spokes_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.spokes_to_egress_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.spokes_to_hybrid_dns_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.spokes_to_ingress_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.spokes_to_inspection_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.spokes_to_shared_services_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_central_vpcs"></a> [central\_vpcs](#input\_central\_vpcs) | Configuration of the Central VPCs - used to centralized different services. You can create the following Central VPCs: <br>- `inspection`      = To centralize the traffic inspection. If created, all the traffic between Spoke VPCs (East/West) and to the Internet (North/South) will be passed to this VPC. You can create Internet access in this VPC, if no Egress VPC is created.<br>- `egress`          = To centralize Internet access. You cannot create an Egress VPC and an Inspection VPC with Internet access at the same time.<br>- `shared_services` = To centralize VPC endpoint access. This VPC won't have Internet access, and its TGW attachment will be propaged directly to the Spoke TGW Route Table directly.<br>- `ingress`         = To centralize ingress access to resources from a central VPC - no distributed Internet access.<br>- `hybrid_dns`      = To centralize Hybrid DNS configuration (Route 53 Resolver endpoints or a 3rd-party solution) outside of the Shared Services VPC. This VPC won't have Internet access, and its TGW attachment will be propaged directly to the Spoke TGW Route Table directly.<br><br>For more information of the input format and the resources created in each Central VPC, check the section **Central VPCs** in the README. | `any` | n/a | yes |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | String to identify the whole Hub and Spoke Architecture | `string` | n/a | yes |
| <a name="input_transit_gateway"></a> [transit\_gateway](#input\_transit\_gateway) | Transit Gateway configuration. Either you specify the `id` of a current Transit Gateway you created, or you the `configuration` variables to create a new one. <br>The following parameters are accepted when configuring a new Transit Gateway:<br>- `name`                           = (Optional\|String) Name of the new Transit Gateway to create.<br>- `amazon_side_asn`                = (Optional\|Int) Private Autonomous System Number (ASN) for the Amazon side of a BGP session. The range is `64512` to `65534` for 16-bit ASNs and `4200000000` to `4294967294` for 32-bit ASNs. Default value: `64512`.<br>- `auto_accept_shared_attachments` = (Optional\|String) Whether resource attachment requests are automatically accepted. Valid values: `disable`, `enable`. Default value: `disable`.<br>- `dns_support`                    = (Optional\|String) Whether DNS support is enabled. Valid values: `disable`, `enable`. Default value: `enable`.<br>- `vpn_ecmp_support`               = (Optional\|String) Whether VPN Equal Cost Multipath Protocol support is enabled. Valid values: `disable`, `enable`. Default value: `enable`.<br>- `resource_share`                 = (Optional\|Bool) Whether the Transit Gateway is shared via Resource Access Manager or not. Valid values: `false`, `true`. Default value: `false`.<br>- `tags`                           = (Optional\|map(string)) Tags to apply to the Transit Gateway. | `any` | n/a | yes |
| <a name="input_spoke_vpcs"></a> [spoke\_vpcs](#input\_spoke\_vpcs) | Definition of the Spoke VPCs to include in the Hub and Spoke architecture. It is out of the scope of this module the creation of the Spoke VPCs and their attachments to the Transit Gateway. The module will only handle the VPC attachments and the routing logic in the Transit Gateway.<br>**Attributes to define**:<br>- `number_spokes`   = (Optional\|Int) **If set need to be greater than 0**. The number of Spoke VPCs attached to the Transit Gateway.<br>- `cidrs_list`      = (Optional\|list(string)) List of the CIDR blocks of all the VPCs attached to the Transit Gateway. The list of CIDR blocks will be used in the Central VPCs to route to the Transit Gateway - in those central VPCs that have already a route to the Internet (0.0.0.0/0). If not specified, no routes will be created and you will need to create them outside this module.<br>- `vpc_attachments` = (Optional\|list(string)) List of Spoke VPC Transit Gateway attachments. The VPC attachments will be associated to the Spoke TGW Route Table, and propagated to the corresponding Central TGW Route Tables. | `any` | <pre>{<br>  "number_spokes": 0<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_central_vpcs"></a> [central\_vpcs](#output\_central\_vpcs) | Central VPCs created. |
| <a name="output_firewall"></a> [firewall](#output\_firewall) | Firewall solution created. |
| <a name="output_tgw_rt_central_vpcs"></a> [tgw\_rt\_central\_vpcs](#output\_tgw\_rt\_central\_vpcs) | Transit Gateway Route Tables associated to the Central VPC attachments. |
| <a name="output_tgw_rt_spoke_vpc"></a> [tgw\_rt\_spoke\_vpc](#output\_tgw\_rt\_spoke\_vpc) | Transit Gateway Route Table associated to the Spoke VPCs. |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | AWS Transit Gateway. |
<!-- END_TF_DOCS -->
