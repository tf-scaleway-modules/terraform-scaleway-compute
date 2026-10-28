# resource-timeouts Specification

## Purpose
The `timeouts` input that sets create, update and delete timeouts on instances and, for create and delete, on SBS block volumes.

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
The module SHALL apply `timeouts.create` and `timeouts.delete` to every `scaleway_block_volume`; `timeouts.update` SHALL NOT be applied to block volumes.

#### Scenario: Block volume create timeout
- **WHEN** `timeouts = { create = "15m" }` and an instance has an `sbs_5k` additional volume
- **THEN** the block volume has create timeout `"15m"` and delete timeout `"10m"`

### Requirement: Timeouts scope
The `timeouts` input SHALL apply only to `scaleway_instance_server` (create, update, delete) and `scaleway_block_volume` (create, delete). Public IPs, security groups, security group rules, local volumes, snapshots, the placement group and the SSH key SHALL keep the provider defaults, and the README SHALL say so.

#### Scenario: Security group timeouts
- **WHEN** `timeouts = { create = "20m" }`
- **THEN** security groups have no module-set timeout
