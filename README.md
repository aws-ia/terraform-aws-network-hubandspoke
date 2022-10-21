<!-- BEGIN_TF_DOCS -->
# AWS Hub and Spoke Architecture with AWS Transit Gateway - Terraform Module

[AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html) is a network hub that you can use to interconnect your VPCs and on-premises networks. With it, you can create hub and spoke architectures to control how your VPCs and on-prem resources communicate between them. In addition, you can centralize different services - like traffic inspection or the connection to VPC endpoints - and therefore avoid extra costs by overprovisioning those services.

This Terraform module helps you create the base of your networking infrastructure in AWS, by provisioning a Hub and Spoke Architecture with AWS Transit Gateway. You can indicate which resources you want to centralize - by defining which central VPCs you want to create -, and you get the Transit Gateway, VPCs, and routing needed to achieve the interconnection. The only thing you will need to do later is place your worloads and services to centralize.

## Usage

### AWS Transit Gateway

You can either define a current Transit Gateway by passing its ID using the `transit_gateway_id` variable, or let the Hub and Spoke Module to create one for you by using the `transit_gateway_attributes` variable.

The attributes you can define ing `transit_gateway_attributes` are the following ones:

- `name` = (Optional|string) Name to apply to the new Transit Gateway.
- `description` = (Optional|string) Description of the new Transit Gateway
- `amazon_side_asn` = (Optional|number) Private Autonomous System Number (ASN) for the Amazon side of a BGP session. The range is `64512` to `65534` for 16-bit ASNs and `4200000000` to `4294967294` for 32-bit ASNs. It is recommended to configure one to avoid ASN overlap. Default value: `64512`.
- `auto_accept_shared_attachments` = (Optional|string) Wheter the attachment requests are automatically accepted. Valid values: `disable` (default) or `enable`.
- `dns_support` = (Optional|string) Wheter DNS support is enabled. Valid values: `disable` or `enable` (default).
- `multicast_support` = (Optional|string) Wheter Multicas support is enabled. Valid values: `disable` (default) or `enable`.
- `transit_gateway_cidr_blocks` = (Optional|list(string)) One or more IPv4/IPv6 CIDR blocks for the Transit Gateway. Must be a size /24 for IPv4 CIDRs, and /64 for IPv6 CIDRs.
- `vpn_ecmp_support` = (Optional|string) Whever VPN ECMP support is enabled. Valid values: `disable` or `enable` (default).
- `tags` = (Optional|map(string)) Key-value tags to apply to the Transit Gateway.

**NOTE**: You can only define `transit_gateway_id` or `transit_gateway_attributes`, but not both variables at the same time.

### Central VPCs

The Central VPCs you can create are: `inspection`, `egress`, `ingress`, `shared_services`, and `hybrid_dns`. The Central VPCs you define have a set of input variables that are common (regardless of the type of VPC to create). These variables are inherited from the [AWS VPC Module](https://github.com/aws-ia/terraform-aws-vpc), which is used to create all the VPCs in this module. The common attributes are the following ones:

- `vpc_id` = (Optional|string) **If you specify this value, no other attributes can be set** The VPC will be attached to the Transit Gateway, and its attachment associate/propagated to the corresponding TGW Route Tables.
- `name` = (Optional|string) Name of the VPC, if a new VPC is created.
- `cidr_block` = (Optional|string) CIDR range to assign to the VPC, if a new VPC is created.
- `az_count` = (Optional|number) Number of Availability Zones to use in each VPC. As best practice, we recommend the use of at least two AZs to ensure high-availability in your solutions.
- `vpc_enable_dns_hostnames` = (Optional|bool) Indicates whether the instances launched in the VPC get DNS hostnames. **Enabled by default**.
- `vpc_enable_dns_support` = (Optional|bool) Indicates whether the DNS resolution is supported for the VPC. If enabled, queries to the Amazon provided DNS server at the 169.254.169.253 IP address, or the reserved IP address at the base of the VPC network range "plus two" succeed. If disabled, the Amazon provided DNS service in the VPC that resolves public DNS hostnames to IP addresses is not enabled. **Enabled by default**.
- `vpc_instance_tenancy` = (Optional|string) The allowed tenancy of instances launched into the VPC.
- `subnet_configuration` = (Optional|any) Configuration of the subnets to create in the VPC. You can define as many subnets as you want, however, depending the type of central VPC, this definition may vary. Below you will see one example per type of Central VPC.
- `vpc_flow_logs` = = (Optional|object(any)) Configuration of the VPC Flow Logs of the VPC configured. Options: "cloudwatch", "s3", "none". The format of the object to define is the following:

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

#### Inspection VPC

When defining a central Inspection VPC, you can define two types: with Internet access (inspection + egress in the same VPC) or without Internet access (if egress is configured, is placed in a different VPC). Each of the types will have a different configuration:

- **Inspection VPC with Internet access**:
    - `public`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. Additionally, it also accepts `nat_gateway_configuration`, where you can specify `all_azs` (by default), `single_az`, or `none`.
    - `endpoints`: This subnet is used to place the firewall endpoints (AWS Network Firewall or any solution with Gateway Load Balancer). You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. By default, it creates the following routes in the subnet's route tables:
        - To the Internet (0.0.0.0/0) via the NAT gateways (if created).
        - To the Transit Gateway ENI(s). The destination passed will be the Network CIDR defined (either via a supernet or a prefix list) in the `spoke_vpcs` variable.
    - `transit_gateway`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. The rest of the variables needed to create the Transit Gateway VPC attachment are handled by the module.

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
            inspection = { netmask = 24 }
            transit_gateway = { netmask = 28 }
        }
    }
}
```

- **Inspection VPC without Internet access**:
    - `endpoints`: This subnet is used to place the firewall endpoints (AWS Network Firewall or any solution with Gateway Load Balancer). You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. By default, it creates the a default route (0.0.0.0/0) to the Transit Gateway ENI(s).
    - `transit_gateway`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. The rest of the variables needed to create the Transit Gateway VPC attachment are handled by the module.

```hcl
central_vpcs = {

    inspection = {
        name = "inspection-vpc"
        cidr_block = "10.10.0.0/16"
        az_count = 2

        subnets = {
            inspection = { netmask = 24 }
            transit_gateway = { netmask = 28 }
        }
    }
}
```

In addition to the subnet definition, two more attributes can be defined in the Inspection VPC:

- `inspection_flow` = (Optional|string) To indicate how the traffic should be inspected. You can define the following values: `all` (default), `east-west`, `north-south`.
- `aws_network_firewall` = (Optional|map(any)) The Hub and Spoke module also support the creation of AWS Network Firewall, using the [AWS Network Firewall module](https://registry.terraform.io/modules/aws-ia/networkfirewall/aws/latest). The module will create the firewall resource and all the routing needed in the Inspection VPC, and you will need to define the following attributes:
    - `name` = (Required|string) Name of the AWS Network Firewall resource.
    - `policy_arn` = (Required|string) ARN of the AWS Network Firewall Policy resource.
    - `policy_change_protection` = (Optional|bool) To indicate whether it is possible to change the associated firewall policy after creation. Defaults to `false`.
    - `subnet_change_protection` = (Optional|bool) To indicate whether it is possible to change the associated subnet(s) after creation. Defaults to `false`.
    - `tags` = (Optional|map(string)) List of tags to apply to the AWS Network Firewall resource.

```hcl
central_vpcs = {

    inspection = {
        name = "inspection-vpc"
        cidr_block = "10.10.0.0/16"
        az_count = 2
        inspection_flow = "east-west"

        aws_network_firewall = {
            name = "ANFW"
            policy_arn = aws_networkfirewall_firewall_policy.anfw_policy.arn
        }

        subnets = {
            inspection = { netmask = 24 }
            transit_gateway = { netmask = 28 }
        }
    }
}
```

#### Egress VPC

When defining a central Egress VPC, the following subnet configuration is expected:

- `public`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. Additionally, it also accepts `nat_gateway_configuration`, where you can specify `all_azs` (by default), `single_az`, or `none`. By default, it creates the a route to the Transit Gateway ENI(s), using as destination the Network CIDR defined (either via a supernet or a prefix list) in the `spoke_vpcs` variable.
- `transit_gateway`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. The rest of the variables needed to create the Transit Gateway VPC attachment are handled by the module. Additionally, it creates a route to the Internet (0.0.0.0/0) via the NAT gateways (if created).

```hcl
central_vpcs = {

    egress = {
        name = "egress-vpc"
        cidr_block = "10.10.0.0/24"
        az_count = 2

        vpc_flow_logs = {
            iam_role_arn = "ROLEARN" # You should add here an IAM role so VPC Flow logs can publish in CloudWatch Logs
            kms_key_id = "KMSARN" # You should add here a KMS Key ARN to encrypt the logs at rest (best practice)

            log_destination_type = "cloudwatch"
            retention_in_days = 7
        }

        subnets = {
            public = {
                name_prefix = "public_egress"
                cidrs = ["10.10.0.0/28", "10.10.0.16/28"]
                nat_gateway_configuration = "all_azs"
            }
            transit_gateway = {
                name_prefixt = "tgw_egress"
                cidrs = ["10.10.0.32/28", "10.10.0.48/28"]
            }
        }
}
```

**NOTE** Both Inspection VPC with public subnets and Egress VPC cannot be created at the same time.

#### Shared Services VPC

When defining a central Shared Services VPC, three subnet types are expected: `endpoints` (to place VPC Interface endpoints), `dns` (to place Route 53 Resolver endpoints, or your own DNS solution in AWS), and `transit_gateway`. Two types of VPC can be created: with DNS subnets, and without DNS subnets.

- **Shared Services VPC with only "endpoints" subnets**:
    - `endpoints`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. By default, it creates the a default route (0.0.0.0/0) to the Transit Gateway ENI(s).
    - `transit_gateway`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. The rest of the variables needed to create the Transit Gateway VPC attachment are handled by the module.

```hcl
central_vpcs = {

    shared_services = {
        name = "shared-services-vpc"
        cidr_block = "10.10.0.0/24"
        az_count = 2

        subnets = {
            endpoints = { netmask = 28 }
            transit_gateway = { netmask = 28 }
        }
    }
}
```

- **Shared Services VPC with "endpoints" and "dns" subnets**:
    - `endpoints`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. By default, it creates the a default route (0.0.0.0/0) to the Transit Gateway ENI(s).
    - `dns`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. By default, it creates the a default route (0.0.0.0/0) to the Transit Gateway ENI(s).
    - `transit_gateway`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. The rest of the variables needed to create the Transit Gateway VPC attachment are handled by the module.

```hcl
central_vpcs = {

    shared_services = {
        name = "shared-services-vpc"
        cidr_block = "10.10.0.0/24"
        az_count = 2

        subnets = {
            endpoints = { netmask = 28 }
            dns = { netmask = 28 }
            transit_gateway = { netmask = 28 }
        }
    }
}
```

**NOTE** Both Shared Services VPC with "dns" subnets and Hybrid DNS VPC cannot be created at the same time.

#### Hybrid DNS VPC

When defining a central Hybrid DNS VPC, the following subnet configuration is expected:

- `endpoints`: To place Route 53 Resolver endpoints, or your own DNS solution in AWS. You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. By default, it creates the a default route (0.0.0.0/0) to the Transit Gateway ENI(s).
- `transit_gateway`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. The rest of the variables needed to create the Transit Gateway VPC attachment are handled by the module.

```hcl
central_vpcs = {

    hybrid_dns = {
        name = "hybrid-dns-vpc"
        cidr_block = "10.10.0.0/24"
        az_count = 2

        vpc_flow_logs = {
            iam_role_arn = "ROLEARN" # You should add here an IAM role so VPC Flow logs can publish in CloudWatch Logs
            kms_key_id = "KMSARN" # You should add here a KMS Key ARN to encrypt the logs at rest (best practice)

            log_destination_type = "cloudwatch"
            retention_in_days = 7
        }

        subnets = {
            endpoints = {
                name_prefix = "r53_endpoints"
                cidrs = ["10.10.0.0/28", "10.10.0.16/28"]
            }
            transit_gateway = {
                name_prefixt = "tgw"
                cidrs = ["10.10.0.32/28", "10.10.0.48/28"]
            }
        }
}
```

#### Ingress VPC

When defining a central Ingress VPC, the following subnet configuration is expected:

- `public`: To place your entry point to AWS from the Internet (Elastic Load Balancer, for example). You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. By default, it creates the a route (0.0.0.0/0) to the Transit Gateway ENI(s), using as destination the Network CIDR defined (either via a supernet or a prefix list) in the `spoke_vpcs` variable.
- `transit_gateway`: You can define the following attributes: `cidrs`, `netmask`, `name_prefix`, `tags`. The rest of the variables needed to create the Transit Gateway VPC attachment are handled by the module.

```hcl
central_vpcs = {

    ingress = {
        name = "ingress-vpc"
        cidr_block = "10.10.0.0/24"
        az_count = 2

        vpc_flow_logs = {
            iam_role_arn = "ROLEARN" # You should add here an IAM role so VPC Flow logs can publish in CloudWatch Logs
            kms_key_id = "KMSARN" # You should add here a KMS Key ARN to encrypt the logs at rest (best practice)

            log_destination_type = "cloudwatch"
            retention_in_days = 7
        }

        subnets = {
            public = { cidrs = ["10.10.0.0/28", "10.10.0.16/28"] }
            transit_gateway = { cidrs = ["10.10.0.32/28", "10.10.0.48/28"] }
        }
}
```

### Spoke VPCs

This variable is used to provide the Hub and Spoke module the neccessary information about the Spoke VPCs created. Note that the module does not create the VPCs, and the information you pass is the VPC IDs, and Transit Gateway VPC attachment IDs. It is recommended the use of the following [AWS VPC Module](https://github.com/aws-ia/terraform-aws-vpc) to simplify your infrastructure creation - also because the Hub and Spoke module makes use of the VPC module to create the Central VPCs.

Within this variable, a map of routing domains is expected. The *key* of each map will defined that specific routing domain (e.g. prod, nonprod, etc.) and a Transit Gateway Route Table for that routing domain will be created. Inside each routing domain definition, you can define a map of VPCs with the following attributes:

- `vpc_id` = (Optional|string) VPC ID. *This value is not used in this version of the module, we keep it as placehoder when adding support for centralized VPC endpoints*.
- `transit_gateway_attachment_id` = (Optional|string) Transit Gateway VPC attachment ID.

```hcl
spoke_vpcs = {
    production = {
        prod1 = {
            vpc_id = vpc-ID1
            transit_gateway_attachment_id = tgw-attach-ID1
        }
        prod2 = {
            vpc_id = vpc-ID2
            transit_gateway_attachment_id = tgw-attach-ID2
        }
    }
    nonproduction = {
        nonprod = {
            vpc_id = vpc-ID
            transit_gateway_attachment_id = tgw-attach-ID
        }
      }
    }
}
```

### Network Definition

This variable is used to define the IPv4 CIDR block(s) of all the AWS network. Two different types of definition are allowed: **CIDR** (Supernet's CIDR block) or **PREFIX\_LIST** (managed prefix list ID). The variable is an *object type*, composed by two attributes:

* `type`= (string) Defines the type of network definition provided. It has to be either `CIDR` (Supernet's CIDR Block) or `PREFIX_LIST` (prefix list ID containing all the CIDR blocks of the network)
* `value` = (string) Either a Supernet's CIDR Block or a prefix list ID. This value needs to be consistent with the `type` provided in this variable.

```hcl
network_definition = {
    type = "PREFIX_LIST"
    value = pl-id
}
```

```hcl
network_definition = {
    type = "CIDR"
    value = "10.0.0.0/8"
}
```

### Deployment Considerations

#### Terraform Apply - Target

Due to some limitations with Terraform, some resources need to be created beforehand (using `-target`):

- Spoke VPCs' Transit Gateway VPC attachment IDs - needed to create the Transit Gateway Route Tables (for each segment), and the Transit Gateway Associations and Propagations. To deploy everything without problems, you can proceed in two ways:
    - Do `-target` of the Transit Gateway attachments of your Spoke VPCs, and then proceed to deploy the Hub and Spoke architecture.
    - Deploy your Spoke VPCs and Hub and Spoke module without the `spoke_vpcs` variable. Once all the resources are created, add this attribute to the definition and update the Hub and Spoke architecture (as now the TGW attachments are created).
- Managed Prefix List - if building an AWS Network Firewall resource in the Inspection VPC, as the module gets the list of CIDRs from the prefix list to create the routes to the Inspection endpoints. Terraform needs to know this value when created before creating the VPC routes.

In the *./examples* folder you can find different deployment examples where you can check how you can use `-target` to deploy all the resources without problems.

#### Cross-segment (Spoke VPCs) communication

Each Spoke VPC segment created is independent between each other, meaning that inter-segment communication is not allowed. However, if you add an Inspection VPC with the traffic inspection flow as `all` or `east-west`, potentially you can have communication between segments. **You need to block or allow inter-segment communication in the firewall solution deployed**.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.73.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.73.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_network_firewall"></a> [aws\_network\_firewall](#module\_aws\_network\_firewall) | aws-ia/networkfirewall/aws | = 0.0.2 |
| <a name="module_central_vpcs"></a> [central\_vpcs](#module\_central\_vpcs) | aws-ia/vpc/aws | = 3.0.1 |
| <a name="module_spoke_vpcs"></a> [spoke\_vpcs](#module\_spoke\_vpcs) | ./modules/spoke_vpcs | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway_prefix_list_reference.egress_to_inspection_network_prefix_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_prefix_list_reference) | resource |
| [aws_ec2_transit_gateway_prefix_list_reference.ingress_to_inspection_network_prefix_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_prefix_list_reference) | resource |
| [aws_ec2_transit_gateway_prefix_list_reference.spokes_to_inspection_network_prefix_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_prefix_list_reference) | resource |
| [aws_ec2_transit_gateway_route.egress_to_inspection_network_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.ingress_to_inspection_network_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.inspection_to_egress_default_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.spokes_to_egress_default_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.spokes_to_inspection_default_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.spokes_to_inspection_network_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route_table.tgw_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table_association.tgw_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.hybrid_dns_to_spokes_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.shared_services_to_spokes_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.spokes_to_egress_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.spokes_to_hybrid_dns_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.spokes_to_ingress_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.spokes_to_inspection_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.spokes_to_shared_services_propagation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_managed_prefix_list.data_network_prefix_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_managed_prefix_list) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_central_vpcs"></a> [central\_vpcs](#input\_central\_vpcs) | Configuration of the Central VPCs - used to centralized different services. You can create the following central VPCs: "inspection", "egress", "shared-services", "hybrid-dns", and "ingress".<br>In each Central VPC, You can specify the following attributes:<br>- `vpc_id` = (Optional\|string) **If you specify this value, no other attributes can be set** VPC ID, the VPC will be attached to the Transit Gateway, and its attachment associate/propagated to the corresponding TGW Route Tables.<br>- `cidr_block` = (Optional\|string) CIDR range to assign to the VPC if creating a new VPC.<br>- `az_count` = (Optional\|number) Searches the number of AZs in the region and takes a slice based on this number - the slice is sorted a-z.<br>- `vpc_enable_dns_hostnames` = (Optional\|bool) Indicates whether the instances launched in the VPC get DNS hostnames. Enabled by default.<br>- `vpc_enable_dns_support` = (Optional\|bool) Indicates whether the DNS resolution is supported for the VPC. If enabled, queries to the Amazon provided DNS server at the 169.254.169.253 IP address, or the reserved IP address at the base of the VPC network range "plus two" succeed. If disabled, the Amazon provided DNS service in the VPC that resolves public DNS hostnames to IP addresses is not enabled. Enabled by default.<br>- `vpc_instance_tenancy` = (Optional\|string) The allowed tenancy of instances launched into the VPC.<br>- `vpc_flow_logs` = (Optional\|object(any)) Configuration of the VPC Flow Logs of the VPC configured. Options: "cloudwatch", "s3", "none".<br>- `subnet_configuration` = (Optional\|any) Configuration of the subnets to create in the VPC. Depending the type of central VPC to create, the format (subnets to configure) will be different.<br>To get more information of the format of the variables, check the section "Central VPCs" in the README.<pre></pre> | `any` | n/a | yes |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | String to identify the whole Hub and Spoke environment. | `string` | n/a | yes |
| <a name="input_network_definition"></a> [network\_definition](#input\_network\_definition) | "Definition of the IPv4 CIDR configuration. The definition is done by using two variables:"<br>  - `type` = (string) Defines the type of network definition provided. It has to be either `CIDR` (Supernet's CIDR Block) or `PREFIX_LIST` (prefix list ID containing all the CIDR blocks of the network)<br>  - `value` = (string) Either a Supernet's CIDR Block or a prefix list ID. This value needs to be consistent with the `type` provided in this variable.<pre></pre> | <pre>object({<br>    type  = string<br>    value = string<br>  })</pre> | n/a | yes |
| <a name="input_spoke_vpcs"></a> [spoke\_vpcs](#input\_spoke\_vpcs) | Variable is used to provide the Hub and Spoke module the neccessary information about the Spoke VPCs created. Within this variable, a map of routing domains is expected. The *key* of each map will defined that specific routing domain (e.g. prod, nonprod, etc.) and a Transit Gateway Route Table for that routing domain will be created. Inside each routing domain definition, you can define a map of VPCs with the following attributes:<br>  - `vpc_id` = (Optional\|string) VPC ID. *This value is not used in this version of the module, we keep it as placehoder when adding support for centralized VPC endpoints*.<br>  - `transit_gateway_attachment_id` = (Optional\|string) Transit Gateway VPC attachment ID.<br>To get more information of the format of the variables, check the section "Spoke VPCs" in the README.<pre></pre> | `any` | `{}` | no |
| <a name="input_transit_gateway_attributes"></a> [transit\_gateway\_attributes](#input\_transit\_gateway\_attributes) | Attributes about the new Transit Gateway to create. **If you specify this value, transit\_gateway\_id can't be set**:<br>- `name` = (Optional\|string) Name to apply to the new Transit Gateway.<br>- `description` = (Optional\|string) Description of the Transit Gateway<br>- `amazon_side_asn` = (Optional\|number) Private Autonomous System Number (ASN) for the Amazon side of a BGP session. The range is `64512` to `65534` for 16-bit ASNs and `4200000000` to `4294967294` for 32-bit ASNs. It is recommended to configure one to avoid ASN overlap. Default value: `64512`.<br>- `auto_accept_shared_attachments` = (Optional\|string) Wheter the attachment requests are automatically accepted. Valid values: `disable` (default) or `enable`.<br>- `dns_support` = (Optional\|string) Wheter DNS support is enabled. Valid values: `disable` or `enable` (default).<br>- `multicast_support` = (Optional\|string) Wheter Multicas support is enabled. Valid values: `disable` (default) or `enable`.<br>- `transit_gateway_cidr_blocks` = (Optional\|list(string)) One or more IPv4/IPv6 CIDR blocks for the Transit Gateway. Must be a size /24 for IPv4 CIDRs, and /64 for IPv6 CIDRs.<br>- `vpn_ecmp_support` = (Optional\|string) Whever VPN ECMP support is enabled. Valid values: `disable` or `enable` (default).<br>- `tags` = (Optional\|map(string)) Key-value tags to apply to the Transit Gateway.<pre></pre> | `any` | `{}` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | Transit Gateway ID. **If you specify this value, transit\_gateway\_attributes can't be set**. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_network_firewall"></a> [aws\_network\_firewall](#output\_aws\_network\_firewall) | AWS Network Firewall resource. Check the resource in the Terraform Registry - [aws\_networkfirewall\_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall) - for more information about the output attributes.<pre></pre> |
| <a name="output_central_vpcs"></a> [central\_vpcs](#output\_central\_vpcs) | Central VPCs created. Check the [AWS VPC Module](https://github.com/aws-ia/terraform-aws-vpc) README for more information about the output attributes.<pre></pre> |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | AWS Transit Gateway resource. Check the resource in the Terraform Registry - [aws\_ec2\_transit\_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) - for more information about the output attributes.<pre></pre> |
| <a name="output_transit_gateway_route_tables"></a> [transit\_gateway\_route\_tables](#output\_transit\_gateway\_route\_tables) | Transit Gateway Route Tables. The format of the output is the following one:<pre>transit_gateway_route_tables = {<br>  central_vpcs = {<br>    inspection = { ... }<br>    egress = { ... }<br>    ...<br>  }<br>  spoke_vpcs = {<br>    segment1 = { ... }<br>    segment2 = { ... }<br>    ...<br>  }<br>}</pre>Check the AWS Transit Gateway Route Table resource in the Terraform Registry - [aws\_ec2\_transit\_gateway\_route\_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) for more information about the output attributes.<pre></pre> |
<!-- END_TF_DOCS -->