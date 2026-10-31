# ==============================================================================
# Instance flattening + volume routing tests
# ==============================================================================
# Verifies that instance groups expand into the correct number of instances and
# that additional volumes route to the correct backing resource (l_ssd vs SBS).

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
  mock_resource "scaleway_instance_server" {
    defaults = {
      id          = "fr-par-1/00000000-0000-0000-0000-000000000010"
      root_volume = { volume_id = "fr-par-1/00000000-0000-0000-0000-000000000011" }
    }
  }
}

variables {
  name = "test"
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

# ------------------------------------------------------------------------------
# SBS root volume and deletion protection
# ------------------------------------------------------------------------------

run "sbs_root_volume_requests_iops" {
  command = plan

  variables {
    instances = {
      db = { count = 1, instance_type = "DEV1-S", root_volume_type = "sbs_volume", root_volume_sbs_iops = 15000 }
    }
  }

  assert {
    condition     = scaleway_instance_server.this["db-00"].root_volume[0].volume_type == "sbs_volume"
    error_message = "root_volume_type = sbs_volume should create an SBS root volume."
  }

  assert {
    condition     = scaleway_instance_server.this["db-00"].root_volume[0].sbs_iops == 15000
    error_message = "root_volume_sbs_iops = 15000 should be requested on the root volume."
  }
}

run "sbs_root_volume_without_iops_leaves_api_default" {
  command = plan

  variables {
    instances = {
      db = { count = 1, instance_type = "DEV1-S", root_volume_type = "sbs_volume" }
    }
  }

  assert {
    condition     = local.instances_flat["db-00"].root_volume_iops == null
    error_message = "Without root_volume_sbs_iops no IOPS should be requested."
  }
}

run "enable_protection_protects_servers" {
  command = plan

  variables {
    instances = {
      db = { count = 1, instance_type = "DEV1-S", enable_protection = true }
    }
  }

  assert {
    condition     = scaleway_instance_server.this["db-00"].protected == true
    error_message = "enable_protection = true should protect the server."
  }
}

run "servers_are_unprotected_by_default" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = scaleway_instance_server.this["web-00"].protected == false
    error_message = "Servers should be unprotected by default."
  }
}

# ------------------------------------------------------------------------------
# Backup of SBS root volumes uses block snapshots
# ------------------------------------------------------------------------------

run "sbs_root_backup_creates_block_snapshot" {
  command = plan

  variables {
    instances = {
      cache = { count = 2, instance_type = "DEV1-S", root_volume_type = "sbs_volume", enable_backup_snapshot = true }
      db    = { count = 1, instance_type = "DEV1-S", enable_backup_snapshot = true }
    }
  }

  assert {
    condition     = length(scaleway_block_snapshot.this) == 2 && contains(keys(scaleway_block_snapshot.this), "cache-01")
    error_message = "An sbs_volume root with backup should create one block snapshot per server."
  }

  assert {
    condition     = length(scaleway_instance_snapshot.this) == 1 && contains(keys(scaleway_instance_snapshot.this), "db-00")
    error_message = "Only the l_ssd root should create an instance snapshot."
  }

  assert {
    condition     = scaleway_block_snapshot.this["cache-00"].name == "test-cache-00-snapshot"
    error_message = "Snapshots should be named '<server name>-snapshot'."
  }
}

# ------------------------------------------------------------------------------
# Dual stack public IPs
# ------------------------------------------------------------------------------

run "enable_ipv6_creates_routed_ipv6_ip_per_server" {
  command = plan

  variables {
    instances = {
      web = { count = 2, instance_type = "DEV1-S", enable_ipv6 = true }
      app = { count = 1, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_ip.this) == 3 && length(scaleway_instance_ip.ipv6) == 2
    error_message = "Dual stack should add one IPv6 IP per server of the group only."
  }

  assert {
    condition     = scaleway_instance_ip.ipv6["web-00"].type == "routed_ipv6" && scaleway_instance_ip.this["web-00"].type == "routed_ipv4"
    error_message = "The IPs should be routed_ipv6 and routed_ipv4."
  }

  assert {
    condition     = length(scaleway_instance_server.this["web-00"].ip_ids) == 2 && length(scaleway_instance_server.this["app-00"].ip_ids) == 1
    error_message = "Dual stack servers should list two IP IDs, others one."
  }
}

run "no_public_ip_leaves_ip_ids_empty" {
  command = plan

  variables {
    instances = {
      db = { count = 1, instance_type = "DEV1-S", create_public_ip = false }
    }
  }

  assert {
    condition     = length(scaleway_instance_server.this["db-00"].ip_ids) == 0
    error_message = "A server without public IP should have no IP IDs."
  }
}

run "group_public_ip_type_is_applied" {
  command = plan

  variables {
    instances = {
      v6 = { count = 1, instance_type = "DEV1-S", public_ip_type = "routed_ipv6" }
    }
  }

  assert {
    condition     = scaleway_instance_ip.this["v6-00"].type == "routed_ipv6"
    error_message = "The group public_ip_type should be the IP type."
  }
}

# ------------------------------------------------------------------------------
# Group tags on every group resource
# ------------------------------------------------------------------------------

run "group_tags_reach_volumes_and_ips" {
  command = plan

  variables {
    tags = ["team:platform"]
    instances = {
      db = {
        count         = 1
        tags          = ["tier:data"]
        instance_type = "DEV1-S"
        additional_volumes = [
          { size_gb = 50, type = "l_ssd" },
          { size_gb = 100, type = "sbs_5k" },
        ]
      }
    }
  }

  assert {
    condition     = alltrue([for t in ["team:platform", "group:db", "tier:data"] : contains(scaleway_instance_volume.this["db-00-vol-00"].tags, t)])
    error_message = "Local volumes should carry global tags, group:<group> and the group tags."
  }

  assert {
    condition     = alltrue([for t in ["team:platform", "group:db", "tier:data"] : contains(scaleway_block_volume.this["db-00-vol-01"].tags, t)])
    error_message = "SBS volumes should carry global tags, group:<group> and the group tags."
  }

  assert {
    condition     = contains(scaleway_instance_ip.this["db-00"].tags, "tier:data")
    error_message = "Public IPs should carry the group tags."
  }
}
