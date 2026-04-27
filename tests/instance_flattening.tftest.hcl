# ==============================================================================
# Instance flattening + volume routing tests
# ==============================================================================
# Verifies that instance groups expand into the correct number of instances and
# that additional volumes route to the correct backing resource (l_ssd vs SBS).

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
  mock_resource "scaleway_instance_server" {
    defaults = {
      id          = "00000000-0000-0000-0000-000000000010"
      root_volume = { volume_id = "00000000-0000-0000-0000-000000000011" }
    }
  }
}

variables {
  organization_id = "00000000-0000-0000-0000-000000000000"
  project_name    = "default"
  name            = "test"
}

# ------------------------------------------------------------------------------
# Single-group flattening
# ------------------------------------------------------------------------------

run "single_group_count_3_creates_3_servers" {
  command = plan

  variables {
    instances = {
      web = { count = 3, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_server.this) == 3
    error_message = "count = 3 should produce 3 server resources."
  }

  assert {
    condition     = contains(keys(scaleway_instance_server.this), "web-00")
    error_message = "Instance keys should be zero-padded as '<group>-NN'."
  }

  assert {
    condition     = contains(keys(scaleway_instance_server.this), "web-02")
    error_message = "Last instance key should be web-02 for count = 3."
  }
}

# ------------------------------------------------------------------------------
# Multi-group flattening
# ------------------------------------------------------------------------------

run "multi_group_flattens_to_total_count" {
  command = plan

  variables {
    instances = {
      backend  = { count = 2, instance_type = "GP1-S" }
      frontend = { count = 3, instance_type = "DEV1-M" }
    }
  }

  assert {
    condition     = length(scaleway_instance_server.this) == 5
    error_message = "Two groups (count=2 + count=3) should produce 5 servers."
  }
}

# ------------------------------------------------------------------------------
# count = 0 produces no servers
# ------------------------------------------------------------------------------

run "group_with_count_zero_produces_no_servers" {
  command = plan

  variables {
    instances = {
      placeholder = { count = 0, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_server.this) == 0
    error_message = "count = 0 should produce no server resources."
  }
}

# ------------------------------------------------------------------------------
# Additional volumes route to the correct resource type
# ------------------------------------------------------------------------------

run "sbs_volume_routes_to_block_volume_resource" {
  command = plan

  variables {
    instances = {
      db = {
        count         = 1
        instance_type = "DEV1-S"
        additional_volumes = [
          { size_gb = 100, type = "sbs_5k" }
        ]
      }
    }
  }

  assert {
    condition     = length(scaleway_block_volume.this) == 1
    error_message = "An sbs_5k volume should create one scaleway_block_volume."
  }

  assert {
    condition     = length(scaleway_instance_volume.this) == 0
    error_message = "An sbs_5k volume should NOT create a scaleway_instance_volume (l_ssd)."
  }
}

run "local_volume_routes_to_instance_volume_resource" {
  command = plan

  variables {
    instances = {
      cache = {
        count         = 1
        instance_type = "DEV1-S"
        additional_volumes = [
          { size_gb = 50, type = "l_ssd" }
        ]
      }
    }
  }

  assert {
    condition     = length(scaleway_instance_volume.this) == 1
    error_message = "An l_ssd volume should create one scaleway_instance_volume."
  }

  assert {
    condition     = length(scaleway_block_volume.this) == 0
    error_message = "An l_ssd volume should NOT create a scaleway_block_volume."
  }
}

run "mixed_volume_types_route_separately" {
  command = plan

  variables {
    instances = {
      mixed = {
        count         = 1
        instance_type = "DEV1-S"
        additional_volumes = [
          { size_gb = 50, type = "l_ssd" },
          { size_gb = 100, type = "sbs_5k" },
          { size_gb = 100, type = "sbs_15k" },
        ]
      }
    }
  }

  assert {
    condition     = length(scaleway_instance_volume.this) == 1
    error_message = "Should create one scaleway_instance_volume for the l_ssd."
  }

  assert {
    condition     = length(scaleway_block_volume.this) == 2
    error_message = "Should create two scaleway_block_volume for the SBS volumes."
  }
}

# ------------------------------------------------------------------------------
# Public IP allocation follows create_public_ip
# ------------------------------------------------------------------------------

run "public_ips_allocated_only_for_groups_with_create_public_ip" {
  command = plan

  variables {
    instances = {
      public  = { count = 2, instance_type = "DEV1-S", create_public_ip = true }
      private = { count = 3, instance_type = "DEV1-S", create_public_ip = false }
    }
  }

  assert {
    condition     = length(scaleway_instance_ip.this) == 2
    error_message = "Public IPs should only be allocated for instances with create_public_ip = true."
  }
}

# ------------------------------------------------------------------------------
# Backup snapshots follow enable_backup_snapshot
# ------------------------------------------------------------------------------

run "snapshots_created_only_when_backup_enabled" {
  command = plan

  variables {
    instances = {
      db = {
        count                  = 2
        instance_type          = "DEV1-S"
        enable_backup_snapshot = true
      }
      web = {
        count         = 3
        instance_type = "DEV1-S"
      }
    }
  }

  assert {
    condition     = length(scaleway_instance_snapshot.this) == 2
    error_message = "Snapshots should only be created for instances in groups with enable_backup_snapshot = true."
  }
}
