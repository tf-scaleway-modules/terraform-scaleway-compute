# ==============================================================================
# Conditional resource creation tests
# ==============================================================================
# Verifies that count/for_each toggles produce the expected resource shapes
# without provisioning real infrastructure. Provider calls are mocked.

mock_provider "scaleway" {
  mock_resource "scaleway_block_volume" {
    defaults = { id = "fr-par-1/00000000-0000-0000-0000-000000000001" }
  }
  mock_resource "scaleway_instance_volume" {
    defaults = { id = "fr-par-1/00000000-0000-0000-0000-000000000002" }
  }
  mock_resource "scaleway_instance_ip" {
    defaults = { id = "fr-par-1/00000000-0000-0000-0000-000000000003" }
  }
  mock_resource "scaleway_instance_security_group" {
    defaults = { id = "fr-par-1/00000000-0000-0000-0000-000000000004" }
  }
  mock_resource "scaleway_instance_placement_group" {
    defaults = { id = "fr-par-1/00000000-0000-0000-0000-000000000005" }
  }
}

variables {
  name = "test"
}

# ------------------------------------------------------------------------------
# SSH key creation
# ------------------------------------------------------------------------------

run "ssh_key_not_created_by_default" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_iam_ssh_key.this) == 0
    error_message = "SSH key should not be created when ssh_public_key is null."
  }

  assert {
    condition     = output.ssh_key_id == null
    error_message = "ssh_key_id should be null when no key is created."
  }
}

run "ssh_key_created_from_sensitive_public_key" {
  command = plan

  variables {
    ssh_public_key = "ssh-ed25519 AAAA test@example"
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_iam_ssh_key.this) == 1
    error_message = "SSH key should be created when ssh_public_key is set."
  }
}

# ------------------------------------------------------------------------------
# Shared security group creation
# ------------------------------------------------------------------------------

run "shared_security_group_created_closed_by_default" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_security_group.shared) == 1
    error_message = "Shared security group should be created when security_group.id is null."
  }

  assert {
    condition     = scaleway_instance_security_group.shared[0].inbound_default_policy == "drop" && scaleway_instance_security_group.shared[0].outbound_default_policy == "accept" && scaleway_instance_security_group.shared[0].stateful
    error_message = "Default shared group should drop inbound, accept outbound and be stateful."
  }

  assert {
    condition     = length(scaleway_instance_security_group_rules.shared) == 0
    error_message = "The default shared group should have no rules resource (no SSH rule)."
  }
}

run "shared_security_group_rules_created_when_given" {
  command = plan

  variables {
    security_group = {
      inbound_rules = [{ port = 22, ip_range = "10.0.0.0/8" }]
    }
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_security_group_rules.shared) == 1
    error_message = "A rules resource should be planned when inbound_rules is non-empty."
  }
}

run "shared_security_group_skipped_when_id_given" {
  command = plan

  variables {
    security_group = { id = "fr-par-1/11111111-1111-1111-1111-111111111111" }
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_security_group.shared) == 0 && length(scaleway_instance_security_group_rules.shared) == 0
    error_message = "Shared security group should not be created when security_group.id is set."
  }

  assert {
    condition     = output.shared_security_group_id == "fr-par-1/11111111-1111-1111-1111-111111111111" && length(output.security_groups) == 0
    error_message = "The shared output should be the external ID and no group should be listed."
  }
}

# ------------------------------------------------------------------------------
# Per-group security groups (only created when group has custom rules)
# ------------------------------------------------------------------------------

run "per_group_security_group_not_created_without_custom_rules" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_security_group.group) == 0
    error_message = "No per-group security group should be created when groups don't define custom rules."
  }
}

run "per_group_security_group_created_for_groups_with_custom_rules" {
  command = plan

  variables {
    security_group = {
      inbound_rules = [{ port = 22, ip_range = "10.0.0.0/8" }]
    }
    instances = {
      api = {
        count         = 1
        instance_type = "DEV1-S"
        security_group = {
          inbound_rules = [
            { protocol = "TCP", port = 8080, ip_range = "10.0.0.0/8" }
          ]
        }
      }
      web = {
        count         = 1
        instance_type = "DEV1-S"
      }
    }
  }

  assert {
    condition     = length(scaleway_instance_security_group.group) == 1
    error_message = "Exactly one per-group security group should be created (for the 'api' group)."
  }

  assert {
    condition     = contains(keys(scaleway_instance_security_group.group), "api")
    error_message = "Per-group security group key should be the group name 'api'."
  }

  assert {
    condition     = length(local.security_groups_to_create["api"].inbound_rules) == 2
    error_message = "The per-group rules should be the global rules plus the group rules."
  }
}

run "group_security_group_policy_overrides_global" {
  command = plan

  variables {
    instances = {
      db = {
        count         = 1
        instance_type = "DEV1-S"
        security_group = {
          inbound_default_policy = "accept"
          inbound_rules          = [{ port = 5432, ip_range = "10.0.0.0/8" }]
        }
      }
    }
  }

  assert {
    condition     = scaleway_instance_security_group.group["db"].inbound_default_policy == "accept"
    error_message = "The group inbound policy should override the global one."
  }
}

run "group_security_group_id_skips_per_group_group" {
  command = plan

  variables {
    instances = {
      web = {
        count          = 1
        instance_type  = "DEV1-S"
        security_group = { id = "fr-par-1/22222222-2222-2222-2222-222222222222" }
      }
    }
  }

  assert {
    condition     = length(scaleway_instance_security_group.group) == 0
    error_message = "A group with security_group.id should create no per-group security group."
  }

  assert {
    condition     = scaleway_instance_server.this["web-00"].security_group_id == "fr-par-1/22222222-2222-2222-2222-222222222222"
    error_message = "The server should use the external group ID."
  }
}

# ------------------------------------------------------------------------------
# Placement group creation
# ------------------------------------------------------------------------------

run "placement_group_not_created_by_default" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_placement_group.this) == 0 && output.placement_group_id == null
    error_message = "Placement group should not be created when placement_group is null."
  }
}

run "placement_group_created_with_empty_object" {
  command = plan

  variables {
    placement_group = {}
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_placement_group.this) == 1 && scaleway_instance_placement_group.this[0].policy_type == "max_availability"
    error_message = "placement_group = {} should create one max_availability placement group."
  }
}

run "placement_group_uses_policy_type" {
  command = plan

  variables {
    placement_group = { policy_type = "low_latency" }
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = scaleway_instance_placement_group.this[0].policy_type == "low_latency"
    error_message = "policy_type should be passed to the created placement group."
  }
}

run "placement_group_reuses_existing_id" {
  command = plan

  variables {
    placement_group = { id = "fr-par-1/33333333-3333-3333-3333-333333333333" }
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_placement_group.this) == 0 && output.placement_group_id == "fr-par-1/33333333-3333-3333-3333-333333333333"
    error_message = "placement_group.id should be reused without creating a group."
  }
}
