# security-groups Specification

## Purpose
Shared and per-group security groups, rule merging, selection per server and the security group outputs.

## Requirements

### Requirement: Shared security group
When `security_group.id` is null (default), the module SHALL create one security group named `<name>-shared-sg` with the policies and `stateful` of `security_group` (defaults `drop`, `accept`, `true`), and one rules resource with its `inbound_rules` and `outbound_rules` (default `[]`) when at least one is non-empty.

#### Scenario: Default shared group
- **WHEN** the defaults are used
- **THEN** a `shared` security group is planned with inbound policy `drop`, outbound policy `accept`, stateful, and no rules resource

#### Scenario: No rules at all
- **WHEN** `inbound_rules = []` and `outbound_rules = []`
- **THEN** the shared security group is planned without a rules resource

#### Scenario: Rules given
- **WHEN** `security_group = { inbound_rules = [{ port = 22, ip_range = "10.0.0.0/8" }] }`
- **THEN** one rules resource with that inbound rule is planned

#### Scenario: Shared group disabled
- **WHEN** `security_group = { id = "<id>" }` (an existing group is reused)
- **THEN** no shared security group and no shared rules resource are planned

### Requirement: Per-group security group
The module SHALL create a security group named `<name>-<group>-sg` for each group with `count > 0`, no `security_group.id`, and a non-null `security_group.inbound_rules` or `outbound_rules`; its rules SHALL be the global rules followed by the group's rules without duplicates, and its policies and `stateful` SHALL be the group's value when set, else the global one.

#### Scenario: Group with custom rules
- **WHEN** group `db` sets `security_group = { inbound_rules = [{ port = 5432, ip_range = "10.0.0.0/8" }] }`
- **THEN** a security group for `db` is planned whose inbound rules are the global rules plus port 5432

#### Scenario: Group without custom rules
- **WHEN** no group sets `security_group` rules
- **THEN** no per-group security group is planned

#### Scenario: Group policy override
- **WHEN** group `db` sets rules and `security_group.inbound_default_policy = "accept"` while the global policy is `drop`
- **THEN** the `db` security group has inbound policy `accept`

### Requirement: Security group selection per server
Each server SHALL use, in order of priority, the group's `security_group.id`, else the group's own security group, else the shared security group ID (the created group, or `security_group.id`).

#### Scenario: External security group
- **WHEN** a group sets `security_group = { id = "<id>" }`
- **THEN** its servers use that ID and no per-group security group is planned for it

#### Scenario: Per-group security group
- **WHEN** a group has a per-group security group
- **THEN** its servers use it and other groups keep the shared one

#### Scenario: Caller-provided shared group
- **WHEN** the global `security_group.id` is set
- **THEN** servers without a group-level choice use that ID

### Requirement: Security group outputs
The module SHALL output `shared_security_group_id` (the created group's ID, else `security_group.id`) and `security_groups` (name to `{ id, name }`, with the key `shared` for the created shared group and one key per per-group group).

#### Scenario: Both tiers
- **WHEN** the shared group and a `db` per-group group exist
- **THEN** `security_groups` has the keys `shared` and `db`

#### Scenario: No created group
- **WHEN** `security_group.id` is set and no group has custom rules
- **THEN** `security_groups` is empty

### Requirement: Closed by default
The module SHALL NOT open any port unless the caller lists a rule: the default `security_group` has no inbound rule and drops inbound traffic.

#### Scenario: Default plan
- **WHEN** only `name` and `instances` are set
- **THEN** the shared security group has inbound policy `drop` and no inbound rule

### Requirement: IPv6 rules
The module SHALL accept IPv6 CIDR blocks in the `ip_range` of every rule and send them to the rules resource unchanged.

#### Scenario: IPv6 rule
- **WHEN** a rule has `ip_range = "::/0"`
- **THEN** the planned rule carries `::/0`
