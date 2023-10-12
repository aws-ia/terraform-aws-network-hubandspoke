output "transit_gateway_id" {
  description = "ID of the AWS Transit Gateway resource."
  value       = aws_ec2_transit_gateway.tgw.id
}

output "spoke_vpcs_attributes" {
  description = "Map of Spoke VPCs attributes"
  value = try({ for k, v in module.spoke_vpcs : k => {
    vpc_id                        = v.vpc_attributes.id
    transit_gateway_attachment_id = v.transit_gateway_attachment_id
    }
  }, {})
}
