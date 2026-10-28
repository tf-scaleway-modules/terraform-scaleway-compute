# ==============================================================================
# Plan-time warnings for accepted but ignored inputs
# ==============================================================================

check "group_create_security_group_ignored" {
  assert {
    condition = alltrue([
      for group in values(var.instances) : group.create_security_group == null
    ])
    error_message = "instances[*].create_security_group has no effect and will be removed in a future major release. Set on: ${join(", ", [for name, group in var.instances : name if group.create_security_group != null])}."
  }
}

check "private_network_ip_address_ignored" {
  assert {
    condition = alltrue([
      for network in concat(var.private_networks, flatten([for group in values(var.instances) : group.private_networks])) :
      network.ip_address == null
    ])
    error_message = "private_networks[*].ip_address is not applied: servers get the address assigned by Scaleway on the private network."
  }
}

check "security_group_id_ignored" {
  assert {
    condition     = !(var.create_security_group && var.security_group_id != null)
    error_message = "security_group_id is ignored while create_security_group is true; the created shared security group is used."
  }
}
