# ==============================================================================
# Minimal Example
# ==============================================================================

module "compute" {
  source = "../../"

  name = "minimal-example"

  instances = {
    web = {
      count         = 1
      instance_type = "DEV1-S"
    }
  }

  # Closed by default: list every port you need. Restrict SSH to your own range.
  security_group = {
    inbound_rules = [
      { protocol = "TCP", port = 22, ip_range = "203.0.113.0/24" }
    ]
  }
}
