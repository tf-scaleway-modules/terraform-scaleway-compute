# input-validation Specification

## Purpose
Plan-time `validation` blocks on the module inputs for the global enums and formats (zone, instance type, volume types, instance state, security policies, rule protocol and CIDR, placement group policy, public IP type).

## Requirements

### Requirement: Zone validation
The module SHALL accept only a `zone` of the form `fr-par-N`, `nl-ams-N` or `pl-waw-N` with `N` between 1 and 3.

#### Scenario: Valid zone accepted
- **WHEN** `zone = "fr-par-1"`
- **THEN** validation passes

#### Scenario: Invalid zone format rejected
- **WHEN** `zone = "fr-par1"` (missing hyphen) or `zone = "us-east-1"`
- **THEN** the plan fails with "Zone must be a valid Scaleway zone"

### Requirement: Instance type format validation
The module SHALL accept only an `instances[*].instance_type` made of uppercase letters, digits, a hyphen and an uppercase alphanumeric suffix (e.g. `DEV1-S`, `GP1-M`, `PRO2-XXS`).

#### Scenario: Valid instance type accepted
- **WHEN** `instance_type = "DEV1-S"`
- **THEN** validation passes

#### Scenario: Invalid instance type rejected
- **WHEN** `instance_type = "invalid-type"`
- **THEN** the plan fails with "Instance type must be a valid Scaleway format"

### Requirement: Root volume type validation
The module SHALL accept only `l_ssd` or `b_ssd` for `instances[*].root_volume_type`.

#### Scenario: Valid root volume type accepted
- **WHEN** `root_volume_type = "l_ssd"`
- **THEN** validation passes

#### Scenario: Invalid root volume type rejected
- **WHEN** `root_volume_type = "ssd"`
- **THEN** the plan fails with "Root volume type must be 'l_ssd' or 'b_ssd'."

### Requirement: Instance state validation
The module SHALL accept only `started`, `stopped` or `standby` for `instances[*].state`.

#### Scenario: Valid state accepted
- **WHEN** `state = "started"`
- **THEN** validation passes

#### Scenario: Invalid state rejected
- **WHEN** `state = "running"`
- **THEN** the plan fails with "Instance state must be 'started', 'stopped', or 'standby'."

### Requirement: Additional volume type validation
The module SHALL accept only `l_ssd`, `sbs_5k` or `sbs_15k` for `instances[*].additional_volumes[*].type`.

#### Scenario: Valid volume type accepted
- **WHEN** `type = "sbs_5k"`
- **THEN** validation passes

#### Scenario: Invalid volume type rejected
- **WHEN** `type = "sbs_10k"`
- **THEN** the plan fails with "Additional volume type must be 'l_ssd', 'sbs_5k', or 'sbs_15k'."

### Requirement: Global rule protocol validation
The module SHALL accept only `TCP`, `UDP`, `ICMP` or `ANY` for the `protocol` of every entry of the global `inbound_rules` and `outbound_rules`.

#### Scenario: Valid protocol accepted
- **WHEN** `inbound_rules = [{ protocol = "TCP", port = 22 }]`
- **THEN** validation passes

#### Scenario: Invalid inbound protocol rejected
- **WHEN** `inbound_rules = [{ protocol = "HTTP", port = 80 }]`
- **THEN** the plan fails with "Inbound rule protocol must be 'TCP', 'UDP', 'ICMP', or 'ANY'."

#### Scenario: Invalid outbound protocol rejected
- **WHEN** `outbound_rules = [{ protocol = "HTTP", port = 80 }]`
- **THEN** the plan fails with "Outbound rule protocol must be 'TCP', 'UDP', 'ICMP', or 'ANY'."

### Requirement: Global rule CIDR validation
The module SHALL require the `ip_range` of every entry of the global `inbound_rules` and `outbound_rules` to be a valid IPv4 CIDR block (`a.b.c.d/n` with octets 0-255 and a prefix length 0-32).

#### Scenario: Valid CIDR accepted
- **WHEN** `ip_range = "10.0.0.0/8"`
- **THEN** validation passes

#### Scenario: Missing prefix rejected
- **WHEN** `inbound_rules = [{ protocol = "TCP", port = 22, ip_range = "10.0.0.0" }]`
- **THEN** the plan fails with "Inbound rule ip_range must be valid CIDR notation"

#### Scenario: Out-of-range CIDR rejected
- **WHEN** `inbound_rules = [{ protocol = "TCP", port = 22, ip_range = "999.0.0.0/99" }]`
- **THEN** the plan fails with "Inbound rule ip_range must be valid CIDR notation"

### Requirement: Security group default policy validation
The module SHALL accept only `accept` or `drop` for `inbound_default_policy` and `outbound_default_policy`.

#### Scenario: Valid policy accepted
- **WHEN** `inbound_default_policy = "drop"`
- **THEN** validation passes

#### Scenario: Invalid inbound policy rejected
- **WHEN** `inbound_default_policy = "deny"`
- **THEN** the plan fails with "Inbound default policy must be 'accept' or 'drop'."

#### Scenario: Invalid outbound policy rejected
- **WHEN** `outbound_default_policy = "deny"`
- **THEN** the plan fails with "Outbound default policy must be 'accept' or 'drop'."

### Requirement: Placement group policy validation
The module SHALL accept only `low_latency` or `max_availability` for `placement_group_policy_type`, and only `null`, `optional` or `enforced` for `placement_group_policy_mode`.

#### Scenario: Valid policy type accepted
- **WHEN** `placement_group_policy_type = "max_availability"`
- **THEN** validation passes

#### Scenario: Invalid policy type rejected
- **WHEN** `placement_group_policy_type = "high_availability"`
- **THEN** the plan fails with "Placement group policy type must be 'low_latency' or 'max_availability'."

#### Scenario: Invalid policy mode rejected
- **WHEN** `placement_group_policy_mode = "strict"`
- **THEN** the plan fails with "Placement group policy mode must be 'optional' or 'enforced'."

### Requirement: Public IP type validation
The module SHALL accept only `routed_ipv4`, `routed_ipv6` or `nat` for `public_ip_type`.

#### Scenario: Valid IP type accepted
- **WHEN** `public_ip_type = "routed_ipv4"`
- **THEN** validation passes

#### Scenario: Invalid IP type rejected
- **WHEN** `public_ip_type = "static"`
- **THEN** the plan fails with "Public IP type must be 'routed_ipv4', 'routed_ipv6', or 'nat'."

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

### Requirement: Group rule validation
The module SHALL apply to the `inbound_rules` and `outbound_rules` of every `instances` entry the same rules as to the global ones: `protocol` is `TCP`, `UDP`, `ICMP` or `ANY`; `ip_range` is a valid IPv4 CIDR block; `port` and `port_range` are not both set. It SHALL accept only `accept` or `drop` for a non-null `instances[*].inbound_default_policy` and `instances[*].outbound_default_policy`.

#### Scenario: Valid group rules accepted
- **WHEN** a group sets `inbound_rules = [{ protocol = "TCP", port = 5432, ip_range = "10.0.0.0/8" }]` and `inbound_default_policy = "drop"`
- **THEN** validation passes

#### Scenario: Invalid group rule protocol rejected
- **WHEN** a group sets `inbound_rules = [{ protocol = "HTTP", port = 80 }]`
- **THEN** the plan fails with "Instance group rule protocol must be 'TCP', 'UDP', 'ICMP', or 'ANY'."

#### Scenario: Invalid group rule CIDR rejected
- **WHEN** a group sets `outbound_rules = [{ protocol = "TCP", port = 443, ip_range = "999.0.0.0/99" }]`
- **THEN** the plan fails with "Instance group rule ip_range must be valid CIDR notation"

#### Scenario: Group rule with port and port_range rejected
- **WHEN** a group sets `inbound_rules = [{ port = 443, port_range = "8000-8999" }]`
- **THEN** the plan fails with "Instance group rule cannot specify both 'port' and 'port_range'"

#### Scenario: Invalid group default policy rejected
- **WHEN** a group sets `inbound_default_policy = "deny"` or `outbound_default_policy = "deny"`
- **THEN** the plan fails with "Instance group default policies must be 'accept' or 'drop'."
