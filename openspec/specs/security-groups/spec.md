# security-groups Specification

## Purpose
Shared and per-group security groups, rule merging, selection per server and the security group outputs.

## Requirements

### Requirement: Shared security group
When `create_security_group = true` (default), the module SHALL create one security group named `<name>-shared-sg` with `inbound_default_policy`, `outbound_default_policy` and `stateful` from the inputs, and one rules resource carrying the global `inbound_rules` and `outbound_rules` when at least one of them is non-empty.

#### Scenario: Default shared group
- **WHEN** the defaults are used
- **THEN** a `shared` security group is planned with inbound policy `drop`, outbound policy `accept`, stateful, and one inbound rule for TCP 22

#### Scenario: Shared group disabled
- **WHEN** `create_security_group = false`
- **THEN** no shared security group and no shared rules resource are planned

#### Scenario: No rules at all
- **WHEN** `inbound_rules = []` and `outbound_rules = []`
- **THEN** the shared security group is planned without a rules resource

### Requirement: Per-group security group
The module SHALL create a security group named `<name>-<group>-sg` for each group with `count > 0`, no `security_group_id`, and a non-null `inbound_rules` or `outbound_rules`; its rules SHALL be the global rules followed by the group's rules without duplicates, and its default policies and `stateful` SHALL be the group's value when set, else the global one.

#### Scenario: Group with custom rules
- **WHEN** group `db` sets `inbound_rules = [{ port = 5432, ip_range = "10.0.0.0/8" }]`
- **THEN** a security group for `db` is planned whose inbound rules are the global rules plus port 5432

#### Scenario: Group without custom rules
- **WHEN** no group sets `inbound_rules` or `outbound_rules`
- **THEN** no per-group security group is planned

#### Scenario: Group policy override
- **WHEN** group `db` sets `inbound_rules` and `inbound_default_policy = "accept"` while the global policy is `drop`
- **THEN** the `db` security group has inbound policy `accept`

### Requirement: Security group selection per server
Each server SHALL use, in order of priority, the group's external `security_group_id`, else the group's own security group, else the shared security group ID (the created group, or `security_group_id` when `create_security_group = false`).

#### Scenario: External security group
- **WHEN** a group sets `security_group_id`
- **THEN** its servers use that ID and no per-group security group is planned for it

#### Scenario: Per-group security group
- **WHEN** a group has a per-group security group
- **THEN** its servers use it and other groups keep the shared one

#### Scenario: Caller-provided shared group
- **WHEN** `create_security_group = false` and `security_group_id` is set
- **THEN** servers without a group-level choice use that ID

### Requirement: Security group outputs
The module SHALL output `shared_security_group_id` (the created group's ID, else `security_group_id`), `group_security_group_ids` (group name to ID, for per-group groups only) and `security_groups` (name to `{ id, name }`, with the key `shared` for the shared group and one key per per-group group).

#### Scenario: Both tiers
- **WHEN** the shared group and a `db` per-group group exist
- **THEN** `security_groups` has the keys `shared` and `db`, and `group_security_group_ids` has the key `db`

#### Scenario: No created group
- **WHEN** `create_security_group = false` and no group has custom rules
- **THEN** `security_groups` and `group_security_group_ids` are empty
