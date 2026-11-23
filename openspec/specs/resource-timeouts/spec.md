# resource-timeouts Specification

## Purpose
The `timeouts` input that sets create, update and delete timeouts on instances.

## Requirements

### Requirement: Timeout variable structure
The module SHALL accept a `timeouts` object with optional string fields `create`, `update` and `delete`, each defaulting to `"10m"`, and `timeouts` itself SHALL default to `{}`.

#### Scenario: Default timeouts
- **WHEN** `timeouts` is not set
- **THEN** create, update and delete are `"10m"`

#### Scenario: Partial configuration
- **WHEN** `timeouts = { create = "20m" }`
- **THEN** create is `"20m"` and update and delete stay `"10m"`

#### Scenario: Empty object
- **WHEN** `timeouts = {}`
- **THEN** all three are `"10m"`

### Requirement: Instance timeouts
The module SHALL apply `timeouts.create`, `timeouts.update` and `timeouts.delete` to every `scaleway_instance_server`.

#### Scenario: Custom instance timeouts
- **WHEN** `timeouts = { create = "20m", delete = "15m" }`
- **THEN** each server has create `"20m"`, update `"10m"` and delete `"15m"`

### Requirement: Block volume timeouts
The module SHALL NOT set timeouts on `scaleway_block_volume`, because scaleway provider 2.92 and later no longer accept a `timeouts` block on that resource.

#### Scenario: Block volume uses provider defaults
- **WHEN** `timeouts = { create = "15m" }` and an instance has an `sbs_5k` additional volume
- **THEN** the block volume has no module-set timeout

### Requirement: Timeouts scope
The `timeouts` input SHALL apply only to `scaleway_instance_server` (create, update, delete). SBS block volumes, public IPs, private NICs, security groups, security group rules, local volumes, snapshots (instance and block), the placement group and the SSH key SHALL keep the provider defaults, and the README SHALL say so.

#### Scenario: Security group timeouts
- **WHEN** `timeouts = { create = "20m" }`
- **THEN** security groups have no module-set timeout

#### Scenario: Private NIC timeouts
- **WHEN** `timeouts = { create = "20m" }`
- **THEN** private NICs have no module-set timeout
