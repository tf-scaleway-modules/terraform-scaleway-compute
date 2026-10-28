# ==============================================================================
# Plan-time check tests
# ==============================================================================
# Verifies the `check` blocks in checks.tf warn on the inputs they guard and
# stay silent otherwise. Provider calls are mocked.

mock_provider "scaleway" {
  mock_data "scaleway_account_project" {
    defaults = { id = "00000000-0000-0000-0000-000000000000" }
  }
  mock_resource "scaleway_instance_ip" {
    defaults = { id = "fr-par-1/00000000-0000-0000-0000-000000000003" }
  }
  mock_resource "scaleway_instance_security_group" {
    defaults = { id = "fr-par-1/00000000-0000-0000-0000-000000000004" }
  }
}

variables {
  organization_id = "00000000-0000-0000-0000-000000000000"
  project_name    = "default"
  name            = "test"
  instances = {
    web = { count = 1, instance_type = "DEV1-S" }
  }
}

run "checks_pass_on_defaults" {
  command = plan

  assert {
    condition     = length(scaleway_instance_server.this) == 1
    error_message = "Defaults should plan one server without any check warning."
  }
}

run "warns_when_group_sets_create_security_group" {
  command = plan

  variables {
    instances = {
      web = { count = 1, instance_type = "DEV1-S", create_security_group = false }
    }
  }

  expect_failures = [check.group_create_security_group_ignored]
}

run "warns_when_global_private_network_sets_ip_address" {
  command = plan

  variables {
    private_networks = [
      { id = "fr-par/00000000-0000-0000-0000-000000000006", ip_address = "10.0.0.10" }
    ]
  }

  expect_failures = [check.private_network_ip_address_ignored]
}

run "warns_when_group_private_network_sets_ip_address" {
  command = plan

  variables {
    instances = {
      web = {
        count            = 1
        instance_type    = "DEV1-S"
        private_networks = [{ id = "fr-par/00000000-0000-0000-0000-000000000006", ip_address = "10.0.0.10" }]
      }
    }
  }

  expect_failures = [check.private_network_ip_address_ignored]
}

run "warns_when_security_group_id_set_while_group_is_created" {
  command = plan

  variables {
    create_security_group = true
    security_group_id     = "fr-par-1/00000000-0000-0000-0000-000000000001"
  }

  expect_failures = [check.security_group_id_ignored]
}

run "no_warning_when_security_group_id_is_the_shared_group" {
  command = plan

  variables {
    create_security_group = false
    security_group_id     = "fr-par-1/00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition     = output.shared_security_group_id == "fr-par-1/00000000-0000-0000-0000-000000000001"
    error_message = "security_group_id should be the shared group when create_security_group is false."
  }
}
