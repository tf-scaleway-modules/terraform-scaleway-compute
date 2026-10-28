## MODIFIED Requirements

### Requirement: Server attributes from the group
Each server SHALL take its type, image, state and root volume (`size_in_gb` from `root_volume_size_gb`, `volume_type` from `root_volume_type`, `delete_on_termination = true`) from its group. When the group sets `root_volume_sbs_iops`, the server SHALL request that IOPS for its root volume; otherwise it SHALL leave the IOPS to the API default.

#### Scenario: Group attributes
- **WHEN** a group sets `instance_type = "GP1-S"`, `image = "debian_bookworm"`, `root_volume_size_gb = 50` and `state = "stopped"`
- **THEN** its servers have those type, image, root volume size and state

#### Scenario: SBS root volume with IOPS
- **WHEN** a group sets `root_volume_type = "sbs_volume"` and `root_volume_sbs_iops = 15000`
- **THEN** its servers have an SBS root volume with 15000 IOPS

#### Scenario: SBS root volume without IOPS
- **WHEN** a group sets `root_volume_type = "sbs_volume"` and no `root_volume_sbs_iops`
- **THEN** its servers have an SBS root volume and the plan sets no IOPS

## ADDED Requirements

### Requirement: Server deletion protection
The module SHALL protect the servers of a group against accidental deletion through the Scaleway API when the group sets `enable_protection = true`, and SHALL leave them unprotected otherwise.

#### Scenario: Protection enabled
- **WHEN** a group sets `enable_protection = true`
- **THEN** its servers are planned with deletion protection on

#### Scenario: Default
- **WHEN** a group does not set `enable_protection`
- **THEN** its servers are unprotected and an upgraded configuration shows no change
