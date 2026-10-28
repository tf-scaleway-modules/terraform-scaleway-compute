# runtime-checks Specification

## Purpose
Resource `precondition` blocks that reject inconsistent combinations of inputs at plan time.

## Requirements

### Requirement: SSH key content precondition
The module SHALL fail the plan when `create_ssh_key = true` and both `ssh_public_key` and `ssh_public_key_file` are null.

#### Scenario: SSH key creation with content succeeds
- **WHEN** `create_ssh_key = true` and `ssh_public_key = "ssh-ed25519 AAAA..."`
- **THEN** the plan succeeds

#### Scenario: SSH key creation with file succeeds
- **WHEN** `create_ssh_key = true` and `ssh_public_key_file = "~/.ssh/id_ed25519.pub"` points to a readable file
- **THEN** the plan succeeds

#### Scenario: SSH key creation without source fails
- **WHEN** `create_ssh_key = true` and both `ssh_public_key` and `ssh_public_key_file` are null
- **THEN** the plan fails with "SSH key creation requires either ssh_public_key or ssh_public_key_file to be provided."

### Requirement: External volume single instance precondition
The module SHALL fail the plan when an instance group with a non-empty `external_volume_ids` has `count` greater than 1.

#### Scenario: External volume with single instance succeeds
- **WHEN** a group has `count = 1` and `external_volume_ids = ["vol-123"]`
- **THEN** the plan succeeds

#### Scenario: External volume with multiple instances fails
- **WHEN** a group has `count = 2` and `external_volume_ids = ["vol-123"]`
- **THEN** the plan fails with "External volumes can only be used when instance group count is 1."

### Requirement: Ignored group security group flag warning
The module SHALL emit a plan-time warning, without failing the plan, naming every instance group that sets `create_security_group` to a non-null value, because the attribute has no effect.

#### Scenario: Group sets create_security_group
- **WHEN** a group `web` sets `create_security_group = false`
- **THEN** the check `group_create_security_group_ignored` warns and names `web`, and the plan still succeeds

#### Scenario: Attribute unset
- **WHEN** no group sets `create_security_group`
- **THEN** the check passes

### Requirement: Ignored private network IP warning
The module SHALL emit a plan-time warning, without failing the plan, when any entry of the global `private_networks` or of a group's `private_networks` sets `ip_address`, because the address is not applied to the server.

#### Scenario: Static IP requested
- **WHEN** `private_networks = [{ id = "<pn>", ip_address = "10.0.0.10" }]`
- **THEN** the check `private_network_ip_address_ignored` warns and the plan still succeeds

#### Scenario: No static IP
- **WHEN** no private network sets `ip_address`
- **THEN** the check passes

### Requirement: Ignored external security group warning
The module SHALL emit a plan-time warning, without failing the plan, when `create_security_group = true` and `security_group_id` is set, because the created shared group is used and the ID is ignored.

#### Scenario: ID set while the group is created
- **WHEN** `create_security_group = true` and `security_group_id = "fr-par-1/00000000-0000-0000-0000-000000000001"`
- **THEN** the check `security_group_id_ignored` warns and the plan still succeeds

#### Scenario: ID used as the shared group
- **WHEN** `create_security_group = false` and `security_group_id` is set
- **THEN** the check passes
