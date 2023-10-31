output "transit_gateway_id" {
  description = "ID of the AWS Transit Gateway resource."
  value       = aws_ec2_transit_gateway.tgw.id
}

output "network_prefix_list_id" {
  description = "ID of the AWS Managed Prefix List resource."
  value       = aws_ec2_managed_prefix_list.network_prefix_list.id
}
