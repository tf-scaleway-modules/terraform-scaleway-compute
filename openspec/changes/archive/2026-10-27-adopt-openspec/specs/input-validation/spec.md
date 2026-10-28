## ADDED Requirements

### Requirement: Project name validation
The module SHALL accept only a `project_name` that starts with a lowercase letter, contains lowercase letters, digits and hyphens, ends with a lowercase letter or digit, and is 2 to 63 characters long.

#### Scenario: Valid project name accepted
- **WHEN** `project_name = "my-project"`
- **THEN** validation passes

#### Scenario: Uppercase rejected
- **WHEN** `project_name = "MyProject"`
- **THEN** the plan fails with "Project name must be lowercase alphanumeric with hyphens"

#### Scenario: Leading digit rejected
- **WHEN** `project_name = "1project"`
- **THEN** the plan fails with "Project name must be lowercase alphanumeric with hyphens"

### Requirement: Instance count range validation
The module SHALL accept only an `instances[*].count` between 0 and 50 inclusive.

#### Scenario: Count at the limit accepted
- **WHEN** a group has `count = 50`
- **THEN** validation passes

#### Scenario: Count above the limit rejected
- **WHEN** a group has `count = 51`
- **THEN** the plan fails with "Instance count per group must be between 0 and 50."

### Requirement: External or custom security group exclusivity
The module SHALL reject an instance group that sets `security_group_id` together with `inbound_rules` or `outbound_rules`.

#### Scenario: External security group without rules accepted
- **WHEN** a group sets `security_group_id = "fr-par-1/00000000-0000-0000-0000-000000000001"` and no rules
- **THEN** validation passes

#### Scenario: Both external ID and rules rejected
- **WHEN** a group sets `security_group_id` and `inbound_rules = [{ port = 443 }]`
- **THEN** the plan fails with "Cannot specify both security_group_id and custom inbound_rules/outbound_rules."

### Requirement: Port or port range exclusivity
The module SHALL reject an entry of the global `inbound_rules` or `outbound_rules` that sets both `port` and `port_range`.

#### Scenario: Port alone accepted
- **WHEN** `inbound_rules = [{ port = 443 }]`
- **THEN** validation passes

#### Scenario: Port range alone accepted
- **WHEN** `inbound_rules = [{ port_range = "8000-8999" }]`
- **THEN** validation passes

#### Scenario: Both inbound rejected
- **WHEN** `inbound_rules = [{ port = 443, port_range = "8000-8999" }]`
- **THEN** the plan fails with "Inbound rule cannot specify both 'port' and 'port_range'"

#### Scenario: Both outbound rejected
- **WHEN** `outbound_rules = [{ port = 443, port_range = "8000-8999" }]`
- **THEN** the plan fails with "Outbound rule cannot specify both 'port' and 'port_range'"
