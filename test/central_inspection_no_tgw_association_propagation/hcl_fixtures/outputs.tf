output "network_firewall_policy_arn" {
  description = "The ARN of the AWS Network Firewall Policy"
  value       = aws_networkfirewall_firewall_policy.anfw_policy.arn
}
