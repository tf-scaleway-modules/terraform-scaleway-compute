# ==============================================================================
# Minimal Example
# ==============================================================================

module "compute" {
  source = "../../"

  organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  project_name    = "default"

  name = "minimal-example"

  instances = {
    web = {
      count         = 1
      instance_type = "DEV1-S"
    }
  }

  inbound_rules = [
    { protocol = "TCP", port = 22 }
  ]
}
