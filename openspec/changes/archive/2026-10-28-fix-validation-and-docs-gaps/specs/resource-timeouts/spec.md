## ADDED Requirements

### Requirement: Timeouts scope
The `timeouts` input SHALL apply only to `scaleway_instance_server` (create, update, delete) and `scaleway_block_volume` (create, delete). Public IPs, security groups, security group rules, local volumes, snapshots, the placement group and the SSH key SHALL keep the provider defaults, and the README SHALL say so.

#### Scenario: Security group timeouts
- **WHEN** `timeouts = { create = "20m" }`
- **THEN** security groups have no module-set timeout
