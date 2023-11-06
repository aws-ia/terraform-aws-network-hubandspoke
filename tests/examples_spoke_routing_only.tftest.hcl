run "validate" {
  command = apply
  module {
    source = "./examples/spokes_routing_only"
  }
}