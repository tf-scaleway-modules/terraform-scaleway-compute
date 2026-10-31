## MODIFIED Requirements

### Requirement: Timeouts scope
The `timeouts` input SHALL apply only to `scaleway_instance_server` (create, update, delete) and `scaleway_block_volume` (create, delete). Public IPs, private NICs, security groups, security group rules, local volumes, snapshots (instance and block), the placement group and the SSH key SHALL keep the provider defaults, and the README SHALL say so.

#### Scenario: Security group timeouts
- **WHEN** `timeouts = { create = "20m" }`
- **THEN** security groups have no module-set timeout

#### Scenario: Private NIC timeouts
- **WHEN** `timeouts = { create = "20m" }`
- **THEN** private NICs have no module-set timeout
