# networking Specification

## Purpose
Public IP allocation per server, IP outputs and private network attachment.

## Requirements

### Requirement: Public IP per server
The module SHALL create one `scaleway_instance_ip` of type `public_ip_type` for each server of a group with `create_public_ip = true` (default) and attach it to that server; servers of other groups SHALL get none.

#### Scenario: Default public IP
- **WHEN** a group has `count = 2` and the default `create_public_ip`
- **THEN** two IPs are planned, keyed like the servers, of type `routed_ipv4`

#### Scenario: No public IP
- **WHEN** a group sets `create_public_ip = false`
- **THEN** no IP is planned for its servers

#### Scenario: Other IP type
- **WHEN** `public_ip_type = "nat"`
- **THEN** every created IP has type `nat`

### Requirement: IP outputs
The module SHALL output `public_ips` and `private_ips` as maps of server key to the server's first public or private address, or `null` when it has none.

#### Scenario: Server without public IP
- **WHEN** a group sets `create_public_ip = false`
- **THEN** `public_ips` maps its servers to `null`

### Requirement: Private network attachment
The module SHALL attach each server to the private networks listed in its group's `private_networks`, or to the global `private_networks` when the group list is empty.

#### Scenario: Global private network
- **WHEN** `private_networks = [{ id = "<pn>" }]` and a group sets none
- **THEN** its servers are attached to `<pn>`

#### Scenario: Group override
- **WHEN** a group sets its own `private_networks`
- **THEN** its servers are attached to those networks only, not to the global ones
