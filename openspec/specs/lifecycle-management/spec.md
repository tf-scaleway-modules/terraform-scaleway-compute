# lifecycle-management Specification

## Purpose
Replacement ordering of public IPs and security groups, and the documented way to protect resources from deletion.

## Requirements

### Requirement: Public IP create before destroy
The module SHALL set `create_before_destroy = true` on every `scaleway_instance_ip`, so a replacement creates the new address before the old one is destroyed.

#### Scenario: IP replacement creates new before destroying old
- **WHEN** a public IP resource requires replacement
- **THEN** the new IP is created before the old one is destroyed

### Requirement: Security group create before destroy
The module SHALL set `create_before_destroy = true` on the shared `scaleway_instance_security_group` and on every per-group `scaleway_instance_security_group`, so a replacement creates the new group before the old one is destroyed.

#### Scenario: Shared security group replacement
- **WHEN** the shared security group requires replacement
- **THEN** the new group is created before the old one is destroyed

#### Scenario: Per-group security group replacement
- **WHEN** a per-group security group requires replacement
- **THEN** the new group is created before the old one is destroyed

### Requirement: Documented prevent destroy pattern
The README SHALL document how a caller protects resources from accidental deletion with `prevent_destroy` in the root module.

#### Scenario: Documentation includes prevent destroy example
- **WHEN** a user reads the README section "Lifecycle Protection"
- **THEN** it shows a `lifecycle { prevent_destroy = true }` example
