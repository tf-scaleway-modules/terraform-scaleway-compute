# ==============================================================================
# Conditional resource creation tests
# ==============================================================================
# Verifies that count/for_each toggles produce the expected resource shapes
# without provisioning real infrastructure. Provider calls are mocked.

mock_provider "scaleway" {
  mock_data "scaleway_account_project" {
    defaults = { id = "00000000-0000-0000-0000-000000000000" }
  }
  mock_resource "scaleway_block_volume" {
    defaults = { id = "00000000-0000-0000-0000-000000000001" }
  }
  mock_resource "scaleway_instance_volume" {
    defaults = { id = "00000000-0000-0000-0000-000000000002" }
  }
  mock_resource "scaleway_instance_ip" {
    defaults = { id = "00000000-0000-0000-0000-000000000003" }
  }
  mock_resource "scaleway_instance_security_group" {
    defaults = { id = "00000000-0000-0000-0000-000000000004" }
  }
  mock_resource "scaleway_instance_placement_group" {
    defaults = { id = "00000000-0000-0000-0000-000000000005" }
  }
}

variables {
  organization_id = "00000000-0000-0000-0000-000000000000"
  project_name    = "default"
  name            = "test"
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
    error_message = "SSH key should not be created when create_ssh_key is false."
  }
}

run "ssh_key_created_when_enabled" {
  command = plan

  variables {
    create_ssh_key = true
    ssh_public_key = "ssh-ed25519 AAAA test@example"
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_iam_ssh_key.this) == 1
    error_message = "SSH key should be created when create_ssh_key is true."
  }
}

# ------------------------------------------------------------------------------
# Shared security group creation
# ------------------------------------------------------------------------------

run "shared_security_group_created_by_default" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_security_group.shared) == 1
    error_message = "Shared security group should be created when create_security_group defaults to true."
  }
}

run "shared_security_group_skipped_when_disabled" {
  command = plan

  variables {
    create_security_group = false
    security_group_id     = "11111111-1111-1111-1111-111111111111"
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_security_group.shared) == 0
    error_message = "Shared security group should not be created when create_security_group is false."
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
    instances = {
      api = {
        count         = 1
        instance_type = "DEV1-S"
        inbound_rules = [
          { protocol = "TCP", port = 8080, ip_range = "10.0.0.0/8" }
        ]
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
    condition     = length(scaleway_instance_placement_group.this) == 0
    error_message = "Placement group should not be created when create_placement_group is false."
  }
}

run "placement_group_created_when_enabled" {
  command = plan

  variables {
    create_placement_group = true
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_placement_group.this) == 1
    error_message = "Placement group should be created when create_placement_group is true."
  }
}
