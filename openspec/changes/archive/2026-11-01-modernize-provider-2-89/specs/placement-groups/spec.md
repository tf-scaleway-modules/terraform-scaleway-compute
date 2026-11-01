## MODIFIED Requirements

### Requirement: Shared placement group
When `placement_group` is `{}` or sets only `policy_type`, the module SHALL create one placement group named `<name>-pg` with that `policy_type` (default `max_availability`), and SHALL place every server without its own `placement_group_id` in it. It SHALL NOT set the deprecated `policy_mode`.

#### Scenario: Placement group created
- **WHEN** `placement_group = {}`
- **THEN** one placement group is planned with policy type `max_availability` and every server references it

#### Scenario: Not created by default
- **WHEN** `placement_group` is left at `null`
- **THEN** no placement group is planned and servers have none

### Requirement: Existing or per-group placement group
When `placement_group.id` is set, servers SHALL use it and none is created; a group's own `placement_group_id` SHALL take precedence over both.

#### Scenario: Existing placement group
- **WHEN** `placement_group = { id = "<id>" }`
- **THEN** servers use `<id>`

#### Scenario: Group override
- **WHEN** a group sets `placement_group_id`
- **THEN** its servers use that ID and the other groups keep the shared one

### Requirement: Placement group output
The module SHALL output `placement_group_id` as the created group's ID, else `placement_group.id` (null when neither).

#### Scenario: Nothing configured
- **WHEN** `placement_group` is null
- **THEN** `placement_group_id` is null
