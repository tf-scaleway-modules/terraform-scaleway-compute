## ADDED Requirements

### Requirement: Shared placement group
When `create_placement_group = true`, the module SHALL create one placement group named `<name>-pg` with `policy_type` from `placement_group_policy_type` and `policy_mode` from `placement_group_policy_mode`, and SHALL place every server without its own `placement_group_id` in it.

#### Scenario: Placement group created
- **WHEN** `create_placement_group = true`
- **THEN** one placement group is planned with policy type `max_availability` and every server references it

#### Scenario: Not created by default
- **WHEN** `create_placement_group` is left at its default
- **THEN** no placement group is planned

### Requirement: Existing or per-group placement group
When no placement group is created, servers SHALL use the global `placement_group_id`; a group's own `placement_group_id` SHALL take precedence over both.

#### Scenario: Existing placement group
- **WHEN** `create_placement_group = false` and `placement_group_id = "<id>"`
- **THEN** servers use `<id>`

#### Scenario: Group override
- **WHEN** a group sets `placement_group_id`
- **THEN** its servers use that ID and the other groups keep the shared one

### Requirement: Placement group output
The module SHALL output `placement_group_id` as the created group's ID, else the `placement_group_id` input (null when neither).

#### Scenario: Nothing configured
- **WHEN** no placement group is created or given
- **THEN** `placement_group_id` is null
