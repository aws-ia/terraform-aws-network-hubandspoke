run "validate" {
  command = apply
  module {
    source = "./examples/central_egress_ingress"
  }
}