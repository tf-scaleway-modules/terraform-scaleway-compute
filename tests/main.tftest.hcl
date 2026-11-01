# ==============================================================================
# Private NIC, output and project/zone tests
# ==============================================================================
# Verifies private NICs (global and group networks, optional security group),
# the shape of the instance, volume and snapshot outputs, and the project/zone
# pass-through. Provider calls are mocked; the mock cannot fill computed blocks
# (public_ips, private_ips), so address lists are asserted empty.

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
  mock_resource "scaleway_instance_server" {
    defaults = {
      id          = "fr-par-1/00000000-0000-0000-0000-000000000010"
      root_volume = { volume_id = "fr-par-1/00000000-0000-0000-0000-000000000011" }
    }
  }
  mock_resource "scaleway_instance_private_nic" {
    defaults = { id = "fr-par-1/00000000-0000-0000-0000-000000000020" }
  }
}

variables {
  name = "test"
  instances = {
    web = { count = 1, instance_type = "DEV1-S" }
  }
}

# ------------------------------------------------------------------------------
# Project and zone resolution
# ------------------------------------------------------------------------------

run "project_and_zone_default_to_provider" {
  command = plan

  # The mock fills computed project_id and zone, so only the inputs are observable.
  assert {
    condition     = var.project_id == null && var.zone == null
    error_message = "project_id and zone should default to null (provider values)."
  }
}

run "explicit_project_and_zone_are_applied" {
  command = plan

  variables {
    project_id = "11111110-d164-47ec-8d04-111111111111"
    zone       = "fr-par-2"
  }

  assert {
    condition     = scaleway_instance_server.this["web-00"].project_id == "11111110-d164-47ec-8d04-111111111111" && scaleway_instance_server.this["web-00"].zone == "fr-par-2"
    error_message = "project_id and zone should be passed to the server."
  }

  assert {
    condition     = scaleway_instance_security_group.shared[0].project_id == "11111110-d164-47ec-8d04-111111111111"
    error_message = "project_id should be passed to the security group."
  }
}

# ------------------------------------------------------------------------------
# Private NICs
# ------------------------------------------------------------------------------

run "no_private_nic_by_default" {
  command = plan

  assert {
    condition     = length(scaleway_instance_private_nic.this) == 0
    error_message = "No private NIC should be planned without private_networks."
  }
}

run "global_private_network_creates_one_nic_per_server" {
  command = plan

  variables {
    private_networks = ["fr-par/00000000-0000-0000-0000-000000000006"]
    instances = {
      web = { count = 2, instance_type = "DEV1-S" }
    }
  }

  assert {
    condition     = length(scaleway_instance_private_nic.this) == 2 && contains(keys(scaleway_instance_private_nic.this), "web-01-pn-00")
    error_message = "A global network should create one NIC per server keyed '<server key>-pn-<NN>'."
  }
}

run "group_private_networks_override_global" {
  command = plan

  variables {
    private_networks = ["fr-par/00000000-0000-0000-0000-000000000006"]
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
      db = {
        count            = 1
        instance_type    = "DEV1-S"
        private_networks = ["fr-par/00000000-0000-0000-0000-000000000007", "fr-par/00000000-0000-0000-0000-000000000008"]
      }
    }
  }

  assert {
    condition     = length(scaleway_instance_private_nic.this) == 3
    error_message = "web gets the global network, db its own two."
  }

  assert {
    condition     = scaleway_instance_private_nic.this["db-00-pn-01"].private_network_id == "fr-par/00000000-0000-0000-0000-000000000008"
    error_message = "The group networks should replace the global ones, in list order."
  }
}

run "server_ignores_private_network_block" {
  command = plan

  variables {
    private_networks = ["fr-par/00000000-0000-0000-0000-000000000006"]
  }

  assert {
    condition     = length(scaleway_instance_server.this["web-00"].private_network) == 0
    error_message = "The server must not carry the inline private_network block."
  }
}

run "nic_security_group_only_with_flag" {
  command = plan

  variables {
    private_networks = ["fr-par/00000000-0000-0000-0000-000000000006"]
    instances = {
      web = { count = 1, instance_type = "DEV1-S" }
      db = {
        count                             = 1
        instance_type                     = "DEV1-S"
        enable_private_nic_security_group = true
        security_group                    = { inbound_rules = [{ port = 5432, ip_range = "172.16.0.0/22" }] }
      }
    }
  }

  assert {
    condition     = scaleway_instance_private_nic.this["web-00-pn-00"].security_group_id == null
    error_message = "NICs without the flag must have no security group."
  }

  assert {
    condition     = scaleway_instance_private_nic.this["db-00-pn-00"].security_group_id == scaleway_instance_security_group.group["db"].id
    error_message = "With the flag the NIC must use the security group of its server."
  }
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

run "instances_output_lists_addresses" {
  command = apply

  variables {
    private_networks = ["fr-par/00000000-0000-0000-0000-000000000006"]
    instances = {
      web = { count = 1, instance_type = "DEV1-S", enable_backup_snapshot = true }
    }
  }

  assert {
    condition     = length(scaleway_instance_private_nic.this) == 1 && length(output.instances["web-00"].private_ips) == 0 && length(output.instances["web-00"].public_ips) == 0
    error_message = "instances should expose public_ips and private_ips lists (empty under the mock)."
  }

  assert {
    condition     = length(output.instances_by_group["web"]["web-00"].private_ips) == 0 && length(output.instances_by_group["web"]["web-00"].public_ips) == 0
    error_message = "instances_by_group should expose public_ips and private_ips lists."
  }

  assert {
    condition     = output.backup_snapshots["web-00"].type == "instance"
    error_message = "backup_snapshots should list the instance snapshot with its type."
  }
}

run "server_without_nic_has_empty_private_ips" {
  command = apply

  assert {
    condition     = length(output.instances["web-00"].private_ips) == 0 && length(output.backup_snapshots) == 0
    error_message = "No NIC means no private address, and no backup means no snapshot."
  }
}

run "volumes_output_merges_local_and_sbs" {
  command = apply

  variables {
    instances = {
      db = {
        count         = 1
        instance_type = "DEV1-S"
        additional_volumes = [
          { size_gb = 50, type = "l_ssd" },
          { size_gb = 100, type = "sbs_5k" },
        ]
      }
    }
  }

  assert {
    condition     = output.volumes["db-00-vol-00"].type == "local" && output.volumes["db-00-vol-01"].type == "sbs"
    error_message = "volumes should merge local and SBS volumes with their type."
  }
}

run "sbs_root_block_snapshot_in_output" {
  command = apply

  variables {
    instances = {
      cache = { count = 1, instance_type = "DEV1-S", root_volume_type = "sbs_volume", enable_backup_snapshot = true }
    }
  }

  assert {
    condition     = output.backup_snapshots["cache-00"].type == "block"
    error_message = "An SBS root snapshot should be typed 'block'."
  }
}
