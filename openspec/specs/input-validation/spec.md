## ADDED Requirements

### Requirement: Zone validation
The module SHALL validate that the `zone` variable matches a valid Scaleway zone format (e.g., `fr-par-1`, `nl-ams-1`, `pl-waw-2`).

#### Scenario: Valid zone accepted
- **WHEN** user provides `zone = "fr-par-1"`
- **THEN** validation passes

#### Scenario: Invalid zone format rejected
- **WHEN** user provides `zone = "fr-par1"` (missing hyphen)
- **THEN** terraform plan fails with error message indicating valid zone format

### Requirement: Instance type format validation
The module SHALL validate that each `instances[*].instance_type` matches the Scaleway instance type format (e.g., `DEV1-S`, `GP1-M`, `PRO2-XXS`).

#### Scenario: Valid instance type accepted
- **WHEN** user provides `instance_type = "DEV1-S"`
- **THEN** validation passes

#### Scenario: Invalid instance type rejected
- **WHEN** user provides `instance_type = "invalid-type"`
- **THEN** terraform plan fails with error message indicating valid instance type format

### Requirement: Root volume type validation
The module SHALL validate that each `instances[*].root_volume_type` is one of the allowed values: `l_ssd` or `b_ssd`.

#### Scenario: Valid root volume type accepted
- **WHEN** user provides `root_volume_type = "l_ssd"`
- **THEN** validation passes

#### Scenario: Invalid root volume type rejected
- **WHEN** user provides `root_volume_type = "ssd"`
- **THEN** terraform plan fails with error listing valid options

### Requirement: Instance state validation
The module SHALL validate that each `instances[*].state` is one of the allowed values: `started`, `stopped`, or `standby`.

#### Scenario: Valid state accepted
- **WHEN** user provides `state = "started"`
- **THEN** validation passes

#### Scenario: Invalid state rejected
- **WHEN** user provides `state = "running"`
- **THEN** terraform plan fails with error listing valid options

### Requirement: Additional volume type validation
The module SHALL validate that each `instances[*].additional_volumes[*].type` is one of the allowed values: `l_ssd`, `sbs_5k`, or `sbs_15k`.

#### Scenario: Valid volume type accepted
- **WHEN** user provides `type = "sbs_5k"`
- **THEN** validation passes

#### Scenario: Invalid volume type rejected
- **WHEN** user provides `type = "sbs_10k"`
- **THEN** terraform plan fails with error listing valid options

### Requirement: Security rule protocol validation
The module SHALL validate that `inbound_rules[*].protocol` and `outbound_rules[*].protocol` are one of: `TCP`, `UDP`, `ICMP`, or `ANY`.

#### Scenario: Valid protocol accepted
- **WHEN** user provides `protocol = "TCP"`
- **THEN** validation passes

#### Scenario: Invalid protocol rejected
- **WHEN** user provides `protocol = "HTTP"`
- **THEN** terraform plan fails with error listing valid protocols

### Requirement: IP range CIDR validation
The module SHALL validate that `inbound_rules[*].ip_range` and `outbound_rules[*].ip_range` are valid CIDR notation.

#### Scenario: Valid CIDR accepted
- **WHEN** user provides `ip_range = "10.0.0.0/8"`
- **THEN** validation passes

#### Scenario: Invalid CIDR rejected
- **WHEN** user provides `ip_range = "10.0.0.0"` (missing prefix)
- **THEN** terraform plan fails with error indicating CIDR format required

### Requirement: Security policy validation
The module SHALL validate that `inbound_default_policy` and `outbound_default_policy` are one of: `accept` or `drop`.

#### Scenario: Valid policy accepted
- **WHEN** user provides `inbound_default_policy = "drop"`
- **THEN** validation passes

#### Scenario: Invalid policy rejected
- **WHEN** user provides `inbound_default_policy = "deny"`
- **THEN** terraform plan fails with error listing valid options

### Requirement: Placement group policy type validation
The module SHALL validate that `placement_group_policy_type` is one of: `low_latency` or `max_availability`.

#### Scenario: Valid policy type accepted
- **WHEN** user provides `placement_group_policy_type = "max_availability"`
- **THEN** validation passes

#### Scenario: Invalid policy type rejected
- **WHEN** user provides `placement_group_policy_type = "high_availability"`
- **THEN** terraform plan fails with error listing valid options

### Requirement: Placement group policy mode validation
The module SHALL validate that `placement_group_policy_mode` is one of: `optional` or `enforced`.

#### Scenario: Valid policy mode accepted
- **WHEN** user provides `placement_group_policy_mode = "optional"`
- **THEN** validation passes

#### Scenario: Invalid policy mode rejected
- **WHEN** user provides `placement_group_policy_mode = "strict"`
- **THEN** terraform plan fails with error listing valid options

### Requirement: Public IP type validation
The module SHALL validate that `public_ip_type` is one of: `routed_ipv4`, `routed_ipv6`, or `nat`.

#### Scenario: Valid IP type accepted
- **WHEN** user provides `public_ip_type = "routed_ipv4"`
- **THEN** validation passes

#### Scenario: Invalid IP type rejected
- **WHEN** user provides `public_ip_type = "static"`
- **THEN** terraform plan fails with error listing valid options
