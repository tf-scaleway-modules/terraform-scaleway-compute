## ADDED Requirements

### Requirement: SSH key content precondition
The module SHALL validate at plan time that when `create_ssh_key = true`, either `ssh_public_key` or `ssh_public_key_file` is provided.

#### Scenario: SSH key creation with content succeeds
- **WHEN** `create_ssh_key = true` and `ssh_public_key = "ssh-ed25519 AAAA..."`
- **THEN** terraform plan succeeds

#### Scenario: SSH key creation with file succeeds
- **WHEN** `create_ssh_key = true` and `ssh_public_key_file = "~/.ssh/id_ed25519.pub"`
- **THEN** terraform plan succeeds

#### Scenario: SSH key creation without source fails
- **WHEN** `create_ssh_key = true` and both `ssh_public_key` and `ssh_public_key_file` are null
- **THEN** terraform plan fails with error "SSH key creation requires either ssh_public_key or ssh_public_key_file"

### Requirement: External volume single instance precondition
The module SHALL validate at plan time that `external_volume_ids` are only used when instance group count is 1, since block volumes cannot be shared across multiple instances.

#### Scenario: External volume with single instance succeeds
- **WHEN** instance group has `count = 1` and `external_volume_ids = ["vol-123"]`
- **THEN** terraform plan succeeds

#### Scenario: External volume with multiple instances fails
- **WHEN** instance group has `count = 2` and `external_volume_ids = ["vol-123"]`
- **THEN** terraform plan fails with error indicating volumes cannot be shared across instances

### Requirement: Mutually exclusive security group precondition
The module SHALL validate at plan time that instance groups do not specify both `security_group_id` (external) and custom `inbound_rules`/`outbound_rules`.

#### Scenario: External security group without rules succeeds
- **WHEN** instance group has `security_group_id = "sg-123"` and no `inbound_rules`
- **THEN** terraform plan succeeds

#### Scenario: Custom rules without external ID succeeds
- **WHEN** instance group has `inbound_rules = [...]` and no `security_group_id`
- **THEN** terraform plan succeeds

#### Scenario: Both external ID and rules fails
- **WHEN** instance group has both `security_group_id = "sg-123"` and `inbound_rules = [...]`
- **THEN** terraform plan fails with error indicating these options are mutually exclusive

### Requirement: Port or port range precondition
The module SHALL validate that security rules specify either `port` or `port_range`, but not both.

#### Scenario: Rule with port succeeds
- **WHEN** security rule has `port = 443` and no `port_range`
- **THEN** terraform plan succeeds

#### Scenario: Rule with port range succeeds
- **WHEN** security rule has `port_range = "8000-8999"` and no `port`
- **THEN** terraform plan succeeds

#### Scenario: Rule with both port and port range fails
- **WHEN** security rule has both `port = 443` and `port_range = "8000-8999"`
- **THEN** terraform plan fails with error indicating only one can be specified
