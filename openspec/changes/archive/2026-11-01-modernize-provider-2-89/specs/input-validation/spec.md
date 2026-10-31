## MODIFIED Requirements

### Requirement: Zone validation
When set, `zone` SHALL be of the form `fr-par-N`, `nl-ams-N` or `pl-waw-N` with `N` between 1 and 3; `null` SHALL select the provider default zone.

#### Scenario: Valid zone accepted
- **WHEN** `zone = "fr-par-1"` or `zone = null`
- **THEN** validation passes

#### Scenario: Invalid zone format rejected
- **WHEN** `zone = "fr-par1"` (missing hyphen) or `zone = "us-east-1"`
- **THEN** the plan fails with "Zone must be a valid Scaleway zone"

### Requirement: Root volume type validation
The module SHALL accept only `l_ssd` or `sbs_volume` for `instances[*].root_volume_type`; `b_ssd` is no longer supported by the provider.

#### Scenario: Valid root volume type accepted
- **WHEN** `root_volume_type = "l_ssd"`
- **THEN** validation passes

#### Scenario: SBS root volume type accepted
- **WHEN** `root_volume_type = "sbs_volume"`
- **THEN** validation passes

#### Scenario: Invalid root volume type rejected
- **WHEN** `root_volume_type = "b_ssd"` (no longer supported) or `root_volume_type = "ssd"`
- **THEN** the plan fails with "Root volume type must be 'l_ssd' or 'sbs_volume'."

## REMOVED Requirements

### Requirement: Global rule protocol validation
**Reason**: Global and group rules now share one validation set on `security_group`.
**Migration**: Replaced by `Security group rule validation`.

### Requirement: Global rule CIDR validation
**Reason**: IPv6 CIDRs are now accepted (dual stack); replaced by `Security group rule validation`.
**Migration**: None for valid IPv4 ranges.

### Requirement: Security group default policy validation
**Reason**: The policies live in `security_group`; replaced by `Security group policy validation`.
**Migration**: Use `security_group = { inbound_default_policy = "drop" }`.

### Requirement: Placement group policy validation
**Reason**: `placement_group_policy_type` and `placement_group_policy_mode` are folded into `placement_group`; the mode is deprecated in the provider.
**Migration**: Replaced by `Placement group validation`.

### Requirement: Public IP type validation
**Reason**: `public_ip_type` moves to the group and drops `nat`; replaced by `Public IP validation`.
**Migration**: Set `public_ip_type` per group.

### Requirement: Project name validation
**Reason**: `project_name` is removed; replaced by `Project ID validation`.
**Migration**: Use `project_id`.

### Requirement: External or custom security group exclusivity
**Reason**: Applies to `security_group` now; replaced by `Security group exclusivity`.
**Migration**: None.

### Requirement: Port or port range exclusivity
**Reason**: Merged into `Security group rule validation`.
**Migration**: None.

### Requirement: Group rule validation
**Reason**: Merged into `Security group rule validation` and `Security group policy validation`.
**Migration**: Move the attributes under the group `security_group` object.

### Requirement: SBS root volume and backup snapshot exclusivity
**Reason**: SBS root volumes are now backed up with `scaleway_block_snapshot`, so the combination is valid.
**Migration**: None; remove any workaround that disabled `enable_backup_snapshot` on SBS roots.

## ADDED Requirements

### Requirement: Project ID validation
When set, `project_id` SHALL be a UUID; `null` SHALL select the provider default project.

#### Scenario: Valid project ID accepted
- **WHEN** `project_id = "11111110-d164-47ec-8d04-111111111111"` or `project_id = null`
- **THEN** validation passes

#### Scenario: Malformed project ID rejected
- **WHEN** `project_id = "my-project"`
- **THEN** the plan fails with "project_id must be a UUID or null."

### Requirement: Security group rule validation
For `security_group` and every `instances[*].security_group`, each inbound and outbound rule SHALL have a `protocol` of `TCP`, `UDP`, `ICMP` or `ANY`, an `ip_range` that is a valid IPv4 or IPv6 CIDR, and not both `port` and `port_range`.

#### Scenario: Valid rules accepted
- **WHEN** a rule is `{ protocol = "TCP", port = 443, ip_range = "10.0.0.0/8" }` or `{ protocol = "ANY", ip_range = "::/0" }`
- **THEN** validation passes

#### Scenario: Invalid protocol rejected
- **WHEN** a global or group rule has `protocol = "HTTP"`
- **THEN** the plan fails with "Security group rule protocol must be 'TCP', 'UDP', 'ICMP', or 'ANY'."

#### Scenario: Invalid CIDR rejected
- **WHEN** a global or group rule has `ip_range = "10.0.0.0"` or `ip_range = "999.0.0.0/99"`
- **THEN** the plan fails with "Security group rule ip_range must be a valid IPv4 or IPv6 CIDR"

#### Scenario: Port and port range rejected
- **WHEN** a global or group rule sets `port = 443` and `port_range = "8000-8999"`
- **THEN** the plan fails with "Security group rule cannot specify both 'port' and 'port_range'"

### Requirement: Security group policy validation
When set, the `inbound_default_policy` and `outbound_default_policy` of `security_group` and of every `instances[*].security_group` SHALL be `accept` or `drop`.

#### Scenario: Valid policy accepted
- **WHEN** `security_group = { inbound_default_policy = "drop" }`
- **THEN** validation passes

#### Scenario: Invalid policy rejected
- **WHEN** a global or group policy is `deny`
- **THEN** the plan fails with "Security group default policies must be 'accept' or 'drop'."

### Requirement: Security group exclusivity
The module SHALL reject a `security_group` or `instances[*].security_group` that sets `id` together with `inbound_rules` or `outbound_rules`.

#### Scenario: External group without rules accepted
- **WHEN** a group sets `security_group = { id = "fr-par-1/00000000-0000-0000-0000-000000000001" }`
- **THEN** validation passes

#### Scenario: ID and rules rejected
- **WHEN** `security_group = { id = "fr-par-1/00000000-0000-0000-0000-000000000001", inbound_rules = [{ port = 443 }] }`, globally or in a group
- **THEN** the plan fails with "Cannot specify both security_group.id and custom inbound_rules/outbound_rules. Use one or the other."

### Requirement: Placement group validation
When `placement_group` is set, `policy_type` SHALL be `low_latency` or `max_availability` and SHALL NOT be combined with `id`.

#### Scenario: Valid placement group accepted
- **WHEN** `placement_group = { policy_type = "low_latency" }` or `placement_group = { id = "<id>" }`
- **THEN** validation passes

#### Scenario: Invalid policy type rejected
- **WHEN** `placement_group = { policy_type = "high_availability" }`
- **THEN** the plan fails with "placement_group.policy_type must be 'low_latency' or 'max_availability'."

#### Scenario: Existing group with a policy rejected
- **WHEN** `placement_group = { id = "<id>", policy_type = "low_latency" }`
- **THEN** the plan fails with "placement_group.policy_type applies only to a created placement group; do not combine it with placement_group.id."

### Requirement: Public IP validation
`instances[*].public_ip_type` SHALL be `routed_ipv4` or `routed_ipv6`, and `enable_ipv6 = true` SHALL require `create_public_ip = true` and `public_ip_type = "routed_ipv4"`.

#### Scenario: Dual stack accepted
- **WHEN** a group sets `enable_ipv6 = true` with the defaults for the other IP attributes
- **THEN** validation passes

#### Scenario: Unknown type rejected
- **WHEN** a group sets `public_ip_type = "nat"`
- **THEN** the plan fails with "Public IP type must be 'routed_ipv4' or 'routed_ipv6'."

#### Scenario: IPv6 without an IPv4 primary rejected
- **WHEN** a group sets `enable_ipv6 = true` and `create_public_ip = false`, or `public_ip_type = "routed_ipv6"`
- **THEN** the plan fails with "enable_ipv6 requires create_public_ip = true and public_ip_type = 'routed_ipv4'."

### Requirement: Private network limit validation
`private_networks` and every `instances[*].private_networks` SHALL list at most 8 networks, the maximum an Instance supports.

#### Scenario: Eight networks accepted
- **WHEN** a group lists eight private network IDs
- **THEN** validation passes

#### Scenario: Nine networks rejected
- **WHEN** the global or a group list has nine IDs
- **THEN** the plan fails with "At most 8 private networks can be attached to an instance."
