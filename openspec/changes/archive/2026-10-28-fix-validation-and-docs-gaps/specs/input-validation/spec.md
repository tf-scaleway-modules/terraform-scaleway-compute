## MODIFIED Requirements

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

## ADDED Requirements

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
