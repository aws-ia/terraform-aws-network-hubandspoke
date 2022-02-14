# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- examples/inspection/modules/compute/main.tf ---

# EC2 INSTACE(s) - 1 per Availability Zone
resource "aws_instance" "ec2_instance" {
  count                       = length(var.subnets)
  ami                         = var.ami
  associate_public_ip_address = false
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.security_group.id]
  subnet_id                   = var.subnets[count.index]
  iam_instance_profile        = var.role_id

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "instance--${var.vpc_name}-${count.index + 1}"
  }
}

# SECURITY GROUP (for the EC2 instances)
resource "aws_security_group" "security_group" {
  name        = var.sg_information.name
  description = var.sg_information.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.sg_information.ingress
    content {
      description = ingress.value.description
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.sg_information.egress
    content {
      description = egress.value.description
      from_port   = egress.value.from
      to_port     = egress.value.to
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name = "security-group-${var.vpc_name}-${var.identifier}"
  }
}