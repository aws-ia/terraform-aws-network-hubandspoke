# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/inspection/policy.tf ---

# AWS Network Firewall Policy (Strict Rule Ordering)
# Default actions: DROP_ALL & ALERT_ALL
resource "aws_networkfirewall_firewall_policy" "anfw_policy" {
  name = "firewall-policy-${var.identifier}"
  firewall_policy {

    # Stateless configuration
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateless_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.drop_remote.arn
    }

    # Stateful configuration
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
    stateful_default_actions = ["aws:drop_strict", "aws:alert_strict"]
    stateful_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.allow_icmp.arn
    }
    stateful_rule_group_reference {
      priority     = 20
      resource_arn = aws_networkfirewall_rule_group.allow_domains.arn
    }
  }
}

# Stateless Rule Group - Dropping any SSH or RDP connection
resource "aws_networkfirewall_rule_group" "drop_remote" {
  capacity = 2
  name     = "drop-remote-${var.identifier}"
  type     = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {

        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              protocols = [6]
              source {
                address_definition = "0.0.0.0/0"
              }
              source_port {
                from_port = 22
                to_port   = 22
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              destination_port {
                from_port = 22
                to_port   = 22
              }
            }
          }
        }

        stateless_rule {
          priority = 2
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              protocols = [27]
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
}

# Stateful Rule Group 1 - Allowing and logging ICMP traffic
# As it uses Strict Rule Ordering, first the "alert" rule is going to log the packet before it is passed. 
resource "aws_networkfirewall_rule_group" "allow_icmp" {
  capacity = 100
  name     = "allow-icmp-${var.identifier}"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_string = <<EOF
      pass icmp any any -> any any (msg: "Allowing ICMP packets"; sid:2; rev:1;)
      EOF
    }
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}

# Stateful Rule Group 2 - Allowing access to .example.com (HTTP) and .amazon.com (HTTPS)
# As it uses Strict Rule Ordering, first the "alert" rule is going to log the packet before it is passed. 
resource "aws_networkfirewall_rule_group" "allow_domains" {
  capacity = 100
  name     = "allow-domains-${var.identifier}"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [for i in var.cidr_blocks.spoke_vpcs : i]
        }
      }
    }
    rules_source {
      rules_string = <<EOF
      pass http $HOME_NET any -> $EXTERNAL_NET 80 (http.host; dotprefix; content:".example.com"; endswith; msg:"Allowing example.com HTTP requests"; sid:892121; rev:1;)
      pass tcp $HOME_NET any <> $EXTERNAL_NET 80 (msg:"Allowing TCP in port 80"; flow:not_established; sid:892123; rev:1;)
      pass tls $HOME_NET any -> $EXTERNAL_NET 443 (tls.sni; dotprefix; content:".amazon.com"; endswith; msg:"Allowing .amazon.com HTTPS requests"; sid:892125; rev:1;)
      pass tcp $HOME_NET any <> $EXTERNAL_NET 443 (msg:"Allowing TCP in port 443"; flow:not_established; sid:892127; rev:1;)
      EOF
    }
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}
