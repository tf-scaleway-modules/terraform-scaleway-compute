## MODIFIED Requirements

### Requirement: Private network attachment
The module SHALL attach each server to the private networks listed in its group's `private_networks`, or to the global `private_networks` when the group list is empty. Only the network `id` is applied: the optional `ip_address` is accepted for compatibility but has no effect, and a warning is emitted when it is set (see `runtime-checks`).

#### Scenario: Global private network
- **WHEN** `private_networks = [{ id = "<pn>" }]` and a group sets none
- **THEN** its servers are attached to `<pn>`

#### Scenario: Group override
- **WHEN** a group sets its own `private_networks`
- **THEN** its servers are attached to those networks only, not to the global ones

#### Scenario: ip_address not applied
- **WHEN** `private_networks = [{ id = "<pn>", ip_address = "10.0.0.10" }]`
- **THEN** the servers are attached to `<pn>` with an address assigned by Scaleway and the plan warns
