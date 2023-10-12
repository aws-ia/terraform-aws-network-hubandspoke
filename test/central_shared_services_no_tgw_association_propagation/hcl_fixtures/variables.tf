variable "identifier" {
  type        = string
  description = "Project identifier."
  default     = "central-egress-ingress"
}

variable "spoke_vpcs" {
  type        = map(any)
  description = "Spoke VPCs."
  default = {
    "vpc1-terratest" = {
      cidr_block = "10.0.0.0/24"
      number_azs = 2
    }
    "vpc2-terratest" = {
      cidr_block = "10.0.1.0/24"
      number_azs = 2
    }
  }
}
