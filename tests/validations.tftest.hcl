# ==============================================================================
# Variable validation tests
# ==============================================================================
# These tests exercise the `validation` blocks on input variables. They run with
# `command = plan` and fail at variable evaluation, so no provider credentials
# or API calls are required.

variables {
  name = "test"
  instances = {
    web = {
      count         = 1
      instance_type = "DEV1-S"
    }
  }
}

mock_provider "scaleway" {
  # Provider >= 2.76 validates ids as zone/uuid
  mock_resource "scaleway_instance_security_group" {
    defaults = {
      id = "fr-par-1/00000000-0000-0000-0000-000000000004"
    }
  }
  mock_resource "scaleway_instance_ip" {
    defaults = {
      id = "fr-par-1/00000000-0000-0000-0000-000000000003"
    }
  }
  mock_resource "scaleway_instance_server" {
    defaults = {
      id          = "fr-par-1/00000000-0000-0000-0000-000000000010"
      root_volume = { volume_id = "fr-par-1/00000000-0000-0000-0000-000000000011" }
    }
  }
}

# ------------------------------------------------------------------------------
# project_id and zone validation
# ------------------------------------------------------------------------------

run "project_id_rejects_non_uuid" {
  command = plan

  variables {
    project_id = "my-project"
  }

  expect_failures = [var.project_id]
}

run "project_id_accepts_uuid" {
  command = plan

  variables {
    project_id = "11111110-d164-47ec-8d04-111111111111"
  }

  assert {
    condition     = scaleway_instance_server.this["web-00"].project_id == "11111110-d164-47ec-8d04-111111111111"
    error_message = "A UUID project_id should be accepted and applied."
  }
}

run "zone_rejects_invalid_region" {
  command = plan

  variables {
    zone = "us-east-1"
  }

  expect_failures = [var.zone]
}

run "zone_rejects_missing_hyphen" {
  command = plan

  variables {
    zone = "fr-par1"
  }

  expect_failures = [var.zone]
}

run "zone_accepts_null" {
  command = plan

  variables {
    zone = null
  }

  assert {
    condition     = length(scaleway_instance_server.this) == 1
    error_message = "A null zone should select the provider default."
  }
}

# ------------------------------------------------------------------------------
# instances validation
# ------------------------------------------------------------------------------

run "instances_rejects_count_above_50" {
  command = plan

  variables {
    instances = {
      web = { count = 51, instance_type = "DEV1-S" }
    }
  }

  expect_failures = [var.instances]
}

run "instances_rejects_invalid_instance_type" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "not-a-real-type" }
    }
  }

  expect_failures = [var.instances]
}

run "instances_rejects_invalid_state" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", state = "paused" }
    }
  }

  expect_failures = [var.instances]
}

run "instances_rejects_invalid_additional_volume_type" {
  command = plan

  variables {
    instances = {
      web = {
        count              = 1
        instance_type      = "DEV1-S"
        additional_volumes = [{ size_gb = 10, type = "magnetic" }]
      }
    }
  }

  expect_failures = [var.instances]
}

# ------------------------------------------------------------------------------
# Root volume type, SBS IOPS and backup snapshot validation
# ------------------------------------------------------------------------------

run "root_volume_type_rejects_invalid_value" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", root_volume_type = "ssd" }
    }
  }

  expect_failures = [var.instances]
}

run "root_volume_type_rejects_b_ssd" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", root_volume_type = "b_ssd" }
    }
  }

  expect_failures = [var.instances]
}

run "root_volume_sbs_iops_rejects_local_root_volume" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", root_volume_type = "l_ssd", root_volume_sbs_iops = 5000 }
    }
  }

  expect_failures = [var.instances]
}

run "root_volume_sbs_iops_rejects_unsupported_value" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", root_volume_type = "sbs_volume", root_volume_sbs_iops = 7000 }
    }
  }

  expect_failures = [var.instances]
}

run "sbs_root_volume_accepts_supported_iops" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", root_volume_type = "sbs_volume", root_volume_sbs_iops = 5000 }
    }
  }

  assert {
    condition     = scaleway_instance_server.this["web-00"].root_volume[0].volume_type == "sbs_volume"
    error_message = "A valid SBS root volume with 5000 IOPS should be accepted."
  }
}

run "sbs_root_volume_accepts_backup_snapshot" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", root_volume_type = "sbs_volume", enable_backup_snapshot = true }
    }
  }

  assert {
    condition     = length(scaleway_block_snapshot.this) == 1
    error_message = "An SBS root volume with backup should be accepted."
  }
}

# ------------------------------------------------------------------------------
# Global security_group validation
# ------------------------------------------------------------------------------

run "security_group_rejects_invalid_protocol" {
  command = plan

  variables {
    security_group = {
      inbound_rules = [{ protocol = "SCTP", port = 22, ip_range = "0.0.0.0/0" }]
    }
  }

  expect_failures = [var.security_group]
}

run "security_group_rejects_invalid_outbound_protocol" {
  command = plan

  variables {
    security_group = {
      outbound_rules = [{ protocol = "HTTP", port = 443 }]
    }
  }

  expect_failures = [var.security_group]
}

run "security_group_rejects_invalid_cidr" {
  command = plan

  variables {
    security_group = {
      inbound_rules = [{ protocol = "TCP", port = 22, ip_range = "10.0.0.0" }]
    }
  }

  expect_failures = [var.security_group]
}

run "security_group_rejects_out_of_range_cidr" {
  command = plan

  variables {
    security_group = {
      outbound_rules = [{ protocol = "TCP", port = 443, ip_range = "10.0.0.0/33" }]
    }
  }

  expect_failures = [var.security_group]
}

run "security_group_rejects_port_and_port_range_together" {
  command = plan

  variables {
    security_group = {
      inbound_rules = [{ protocol = "TCP", port = 22, port_range = "80-90", ip_range = "0.0.0.0/0" }]
    }
  }

  expect_failures = [var.security_group]
}

run "security_group_rejects_invalid_inbound_policy" {
  command = plan

  variables {
    security_group = { inbound_default_policy = "reject" }
  }

  expect_failures = [var.security_group]
}

run "security_group_rejects_invalid_outbound_policy" {
  command = plan

  variables {
    security_group = { outbound_default_policy = "deny" }
  }

  expect_failures = [var.security_group]
}

run "security_group_rejects_id_with_rules" {
  command = plan

  variables {
    security_group = {
      id            = "fr-par-1/11111111-1111-1111-1111-111111111111"
      inbound_rules = [{ port = 443 }]
    }
  }

  expect_failures = [var.security_group]
}

run "security_group_accepts_ipv6_rules" {
  command = plan

  variables {
    security_group = {
      inbound_rules = [
        { protocol = "TCP", port = 443, ip_range = "::/0" },
        { protocol = "ANY", ip_range = "2001:db8::/32" },
      ]
    }
  }

  assert {
    condition     = length(scaleway_instance_security_group_rules.shared) == 1
    error_message = "IPv6 CIDR rules should be accepted."
  }

  assert {
    condition     = contains([for r in scaleway_instance_security_group_rules.shared[0].inbound_rule : r.ip_range], "::/0")
    error_message = "IPv6 ranges should reach the rules resource unchanged."
  }
}

# ------------------------------------------------------------------------------
# Group security_group validation
# ------------------------------------------------------------------------------

run "instances_accept_valid_group_rules" {
  command = plan

  variables {
    instances = {
      web = {
        count         = 1
        instance_type = "DEV1-S"
        security_group = {
          inbound_default_policy = "drop"
          inbound_rules          = [{ protocol = "TCP", port = 5432, ip_range = "10.0.0.0/8" }]
          outbound_rules         = [{ protocol = "UDP", port_range = "50-60", ip_range = "10.0.0.0/8" }]
        }
      }
    }
  }

  assert {
    condition     = length(scaleway_instance_security_group.group) == 1
    error_message = "A valid group-level rule set should plan one per-group security group."
  }
}

run "instances_reject_group_rule_invalid_protocol" {
  command = plan

  variables {
    instances = {
      web = {
        count          = 1
        instance_type  = "DEV1-S"
        security_group = { inbound_rules = [{ protocol = "HTTP", port = 80 }] }
      }
    }
  }

  expect_failures = [var.instances]
}

run "instances_reject_group_rule_invalid_cidr" {
  command = plan

  variables {
    instances = {
      web = {
        count          = 1
        instance_type  = "DEV1-S"
        security_group = { outbound_rules = [{ protocol = "TCP", port = 443, ip_range = "999.0.0.0/99" }] }
      }
    }
  }

  expect_failures = [var.instances]
}

run "instances_reject_group_rule_port_and_port_range" {
  command = plan

  variables {
    instances = {
      web = {
        count          = 1
        instance_type  = "DEV1-S"
        security_group = { inbound_rules = [{ port = 443, port_range = "8000-8999" }] }
      }
    }
  }

  expect_failures = [var.instances]
}

run "instances_reject_invalid_group_inbound_default_policy" {
  command = plan

  variables {
    instances = {
      web = {
        count          = 1
        instance_type  = "DEV1-S"
        security_group = { inbound_default_policy = "deny" }
      }
    }
  }

  expect_failures = [var.instances]
}

run "instances_reject_invalid_group_outbound_default_policy" {
  command = plan

  variables {
    instances = {
      web = {
        count          = 1
        instance_type  = "DEV1-S"
        security_group = { outbound_default_policy = "deny" }
      }
    }
  }

  expect_failures = [var.instances]
}

run "instances_reject_group_security_group_id_with_rules" {
  command = plan

  variables {
    instances = {
      web = {
        count = 1
        security_group = {
          id            = "fr-par-1/11111111-1111-1111-1111-111111111111"
          inbound_rules = [{ protocol = "TCP", port = 80, ip_range = "0.0.0.0/0" }]
        }
        instance_type = "DEV1-S"
      }
    }
  }

  expect_failures = [var.instances]
}

# ------------------------------------------------------------------------------
# Placement group validation
# ------------------------------------------------------------------------------

run "placement_group_rejects_invalid_policy_type" {
  command = plan

  variables {
    placement_group = { policy_type = "high_availability" }
  }

  expect_failures = [var.placement_group]
}

run "placement_group_rejects_id_with_policy_type" {
  command = plan

  variables {
    placement_group = { id = "fr-par-1/33333333-3333-3333-3333-333333333333", policy_type = "low_latency" }
  }

  expect_failures = [var.placement_group]
}

# ------------------------------------------------------------------------------
# Public IP validation
# ------------------------------------------------------------------------------

run "public_ip_type_rejects_nat" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", public_ip_type = "nat" }
    }
  }

  expect_failures = [var.instances]
}

run "enable_ipv6_rejects_group_without_public_ip" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", create_public_ip = false, enable_ipv6 = true }
    }
  }

  expect_failures = [var.instances]
}

run "enable_ipv6_rejects_ipv6_primary" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", public_ip_type = "routed_ipv6", enable_ipv6 = true }
    }
  }

  expect_failures = [var.instances]
}

run "enable_ipv6_accepts_defaults" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", enable_ipv6 = true }
    }
  }

  assert {
    condition     = length(scaleway_instance_ip.ipv6) == 1
    error_message = "enable_ipv6 with default IP attributes should be accepted."
  }
}

# ------------------------------------------------------------------------------
# Private network limit validation
# ------------------------------------------------------------------------------

run "private_networks_reject_nine_global" {
  command = plan

  variables {
    private_networks = [for i in range(9) : "fr-par/00000000-0000-0000-0000-00000000010${i}"]
  }

  expect_failures = [var.private_networks]
}

run "private_networks_reject_nine_in_group" {
  command = plan

  variables {
    instances = {
      web = {
        count            = 1
        instance_type    = "DEV1-S"
        private_networks = [for i in range(9) : "fr-par/00000000-0000-0000-0000-00000000010${i}"]
      }
    }
  }

  expect_failures = [var.instances]
}

run "private_networks_accept_eight" {
  command = plan

  variables {
    private_networks = [for i in range(8) : "fr-par/00000000-0000-0000-0000-00000000010${i}"]
  }

  assert {
    condition     = length(scaleway_instance_private_nic.this) == 8
    error_message = "Eight networks should be accepted and planned as eight NICs."
  }
}
