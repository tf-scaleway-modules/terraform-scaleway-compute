## MODIFIED Requirements

### Requirement: Public IP per server
The module SHALL create one `scaleway_instance_ip` of the group's `public_ip_type` for each server of a group with `create_public_ip = true` (default) and, when `enable_ipv6 = true`, one more `routed_ipv6` IP; it SHALL attach them through the server `ip_ids`. Servers of other groups SHALL get none.

#### Scenario: Default public IP
- **WHEN** a group has `count = 2` and the defaults
- **THEN** two IPs of type `routed_ipv4` are planned, keyed like the servers

#### Scenario: No public IP
- **WHEN** a group sets `create_public_ip = false`
- **THEN** no IP is planned for its servers

#### Scenario: Other IP type
- **WHEN** a group sets `public_ip_type = "routed_ipv6"`
- **THEN** every IP created for it has type `routed_ipv6`

#### Scenario: Dual stack
- **WHEN** a group with `count = 2` sets `enable_ipv6 = true`
- **THEN** four IPs are planned, two `routed_ipv4` and two `routed_ipv6`, and each server lists both in `ip_ids`

### Requirement: IP outputs
The module SHALL output, in `instances` and `instances_by_group`, `public_ips` and `private_ips` as lists of the server's public and private addresses of every family, empty when it has none; private addresses SHALL come from its private NICs.

#### Scenario: Server without public IP
- **WHEN** a group sets `create_public_ip = false`
- **THEN** `public_ips` is empty for its servers

#### Scenario: Dual stack server
- **WHEN** a group sets `enable_ipv6 = true`
- **THEN** `public_ips` holds an IPv4 and an IPv6 address

## REMOVED Requirements

### Requirement: Private network attachment
**Reason**: Servers no longer carry the inline `private_network` block and `ip_address` is removed; attachment is done by private NIC resources.
**Migration**: Pass network IDs in `private_networks`; replaced by `Private NIC attachment`; see the README section "Upgrading from v2 to v3" for the NIC migration.

## ADDED Requirements

### Requirement: Private NIC attachment
The module SHALL create one `scaleway_instance_private_nic`, keyed `<server key>-pn-<NN>` (index in list order), per server and network of its group's `private_networks`, or of the global `private_networks` when the group list is empty, and SHALL NOT set the inline `private_network` block of the server.

#### Scenario: Global private network
- **WHEN** `private_networks = ["<pn>"]` and a group with `count = 2` sets none
- **THEN** two NICs on `<pn>` are planned, one per server

#### Scenario: Group override
- **WHEN** a group sets its own `private_networks`
- **THEN** its servers get NICs on those networks only, not on the global ones

### Requirement: Private NIC security group
When a group sets `enable_private_nic_security_group = true`, the module SHALL set the `security_group_id` of each of its NICs to the security group resolved for its servers; otherwise it SHALL leave it unset, which keeps private traffic unfiltered.

#### Scenario: Filtering enabled
- **WHEN** a group sets `enable_private_nic_security_group = true` and `private_networks = ["<pn>"]`
- **THEN** each NIC of the group references the same security group as its server

#### Scenario: Default
- **WHEN** a group does not set the flag
- **THEN** its NICs have no security group
