# ==============================================================================
# Variable validation tests
# ==============================================================================
# These tests exercise the `validation` blocks on input variables. They run with
# `command = plan` and fail at variable evaluation, so no provider credentials
# or API calls are required.

variables {
  organization_id = "00000000-0000-0000-0000-000000000000"
  project_name    = "default"
  name            = "test"
  instances = {
    web = {
      count         = 1
      instance_type = "DEV1-S"
    }
  }
}

mock_provider "scaleway" {
  mock_data "scaleway_account_project" {
    defaults = {
      id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

# ------------------------------------------------------------------------------
# project_name validation
# ------------------------------------------------------------------------------

run "project_name_rejects_uppercase" {
  command = plan

  variables {
    project_name = "MyProject"
  }

  expect_failures = [var.project_name]
}

run "project_name_rejects_leading_digit" {
  command = plan

  variables {
    project_name = "1project"
  }

  expect_failures = [var.project_name]
}

# ------------------------------------------------------------------------------
# zone validation
# ------------------------------------------------------------------------------

run "zone_rejects_invalid_region" {
  command = plan

  variables {
    zone = "us-east-1"
  }

  expect_failures = [var.zone]
}

# ------------------------------------------------------------------------------
# instances validation
# ------------------------------------------------------------------------------

run "instances_rejects_count_above_50" {
  command = plan

  variables {
    instances = {
      web = {
        count         = 51
        instance_type = "DEV1-S"
      }
    }
  }

  expect_failures = [var.instances]
}

run "instances_rejects_invalid_instance_type" {
  command = plan

  variables {
    instances = {
      web = {
        count         = 1
        instance_type = "not-a-real-type"
      }
    }
  }

  expect_failures = [var.instances]
}

run "instances_rejects_invalid_root_volume_type" {
  command = plan

  variables {
    instances = {
      web = {
        count            = 1
        instance_type    = "DEV1-S"
        root_volume_type = "magnetic"
      }
    }
  }

  expect_failures = [var.instances]
}

run "instances_rejects_invalid_state" {
  command = plan

  variables {
    instances = {
      web = {
        count         = 1
        instance_type = "DEV1-S"
        state         = "paused"
      }
    }
  }

  expect_failures = [var.instances]
}

run "instances_rejects_invalid_additional_volume_type" {
  command = plan

  variables {
    instances = {
      web = {
        count         = 1
        instance_type = "DEV1-S"
        additional_volumes = [
          { size_gb = 10, type = "magnetic" }
        ]
      }
    }
  }

  expect_failures = [var.instances]
}

run "instances_rejects_security_group_id_with_custom_rules" {
  command = plan

  variables {
    instances = {
      web = {
        count             = 1
        instance_type     = "DEV1-S"
        security_group_id = "11111111-1111-1111-1111-111111111111"
        inbound_rules     = [{ protocol = "TCP", port = 80, ip_range = "0.0.0.0/0" }]
      }
    }
  }

  expect_failures = [var.instances]
}

# ------------------------------------------------------------------------------
# Security group policy validation
# ------------------------------------------------------------------------------

run "inbound_default_policy_rejects_invalid_value" {
  command = plan

  variables {
    inbound_default_policy = "reject"
  }

  expect_failures = [var.inbound_default_policy]
}

run "outbound_default_policy_rejects_invalid_value" {
  command = plan

  variables {
    outbound_default_policy = "reject"
  }

  expect_failures = [var.outbound_default_policy]
}

# ------------------------------------------------------------------------------
# inbound_rules / outbound_rules validation
# ------------------------------------------------------------------------------

run "inbound_rules_reject_invalid_protocol" {
  command = plan

  variables {
    inbound_rules = [
      { protocol = "SCTP", port = 22, ip_range = "0.0.0.0/0" }
    ]
  }

  expect_failures = [var.inbound_rules]
}

run "inbound_rules_reject_invalid_cidr" {
  command = plan

  variables {
    inbound_rules = [
      { protocol = "TCP", port = 22, ip_range = "not-a-cidr" }
    ]
  }

  expect_failures = [var.inbound_rules]
}

run "inbound_rules_reject_port_and_port_range_together" {
  command = plan

  variables {
    inbound_rules = [
      { protocol = "TCP", port = 22, port_range = "80-90", ip_range = "0.0.0.0/0" }
    ]
  }

  expect_failures = [var.inbound_rules]
}

# ------------------------------------------------------------------------------
# Placement group validation
# ------------------------------------------------------------------------------

run "placement_group_policy_type_rejects_invalid_value" {
  command = plan

  variables {
    placement_group_policy_type = "spread"
  }

  expect_failures = [var.placement_group_policy_type]
}

run "placement_group_policy_mode_rejects_invalid_value" {
  command = plan

  variables {
    placement_group_policy_mode = "best_effort"
  }

  expect_failures = [var.placement_group_policy_mode]
}

# ------------------------------------------------------------------------------
# Public IP type validation
# ------------------------------------------------------------------------------

run "public_ip_type_rejects_invalid_value" {
  command = plan

  variables {
    public_ip_type = "elastic"
  }

  expect_failures = [var.public_ip_type]
}
