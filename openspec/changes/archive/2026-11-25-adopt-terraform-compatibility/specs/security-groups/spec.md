## MODIFIED Requirements

### Requirement: Security group outputs
The module SHALL output `shared_security_group_id` (the created group's ID, else `security_group.id`) and `security_groups` (name to `{ id, name, srn }`, with the key `shared` for the created shared group and one key per per-group group).

#### Scenario: Both tiers
- **WHEN** the shared group and a `db` per-group group exist
- **THEN** `security_groups` has the keys `shared` and `db`, each with `id`, `name` and `srn`

#### Scenario: No created group
- **WHEN** `security_group.id` is set and no group has custom rules
- **THEN** `security_groups` is empty
