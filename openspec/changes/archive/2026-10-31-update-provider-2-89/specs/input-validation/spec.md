## MODIFIED Requirements

### Requirement: Root volume type validation
The module SHALL accept only `l_ssd`, `b_ssd` or `sbs_volume` for `instances[*].root_volume_type`.

#### Scenario: Valid root volume type accepted
- **WHEN** `root_volume_type = "l_ssd"`
- **THEN** validation passes

#### Scenario: SBS root volume type accepted
- **WHEN** `root_volume_type = "sbs_volume"`
- **THEN** validation passes

#### Scenario: Invalid root volume type rejected
- **WHEN** `root_volume_type = "ssd"`
- **THEN** the plan fails with "Root volume type must be 'l_ssd', 'b_ssd', or 'sbs_volume'."

## ADDED Requirements

### Requirement: Root volume SBS IOPS validation
The module SHALL accept `instances[*].root_volume_sbs_iops` only when `root_volume_type` is `sbs_volume`, and only with the value `5000` or `15000`.

#### Scenario: Valid IOPS accepted
- **WHEN** a group sets `root_volume_type = "sbs_volume"` and `root_volume_sbs_iops = 5000`
- **THEN** validation passes

#### Scenario: IOPS with a local root volume rejected
- **WHEN** a group sets `root_volume_type = "l_ssd"` and `root_volume_sbs_iops = 5000`
- **THEN** the plan fails with "root_volume_sbs_iops requires root_volume_type 'sbs_volume'."

#### Scenario: Unsupported IOPS rejected
- **WHEN** a group sets `root_volume_type = "sbs_volume"` and `root_volume_sbs_iops = 7000`
- **THEN** the plan fails with "root_volume_sbs_iops must be 5000 or 15000."

### Requirement: SBS root volume and backup snapshot exclusivity
The module SHALL reject a group that sets both `root_volume_type = "sbs_volume"` and `enable_backup_snapshot = true`, because backup snapshots are Instance snapshots, which only support local volumes.

#### Scenario: SBS root with backup rejected
- **WHEN** a group sets `root_volume_type = "sbs_volume"` and `enable_backup_snapshot = true`
- **THEN** the plan fails with "enable_backup_snapshot is not supported with root_volume_type 'sbs_volume': Instance snapshots only support local volumes."

#### Scenario: Local root with backup accepted
- **WHEN** a group sets `root_volume_type = "l_ssd"` and `enable_backup_snapshot = true`
- **THEN** validation passes
