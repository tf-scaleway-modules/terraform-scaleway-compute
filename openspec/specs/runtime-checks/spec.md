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
