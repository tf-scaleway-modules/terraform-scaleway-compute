## MODIFIED Requirements

### Requirement: Backup snapshots
For each server of a group with `enable_backup_snapshot = true`, the module SHALL snapshot the root volume as `<server name>-snapshot`: a `scaleway_instance_snapshot` for an `l_ssd` root, a `scaleway_block_snapshot` for an `sbs_volume` root; no snapshot otherwise. The `backup_snapshots` output SHALL list them by server key as `{ id, name, type, srn }`.

#### Scenario: Backup enabled
- **WHEN** group `db` has `count = 2`, `root_volume_type = "l_ssd"` and `enable_backup_snapshot = true`
- **THEN** two instance snapshots are planned, keyed like the servers, each listed with an `srn`

#### Scenario: SBS root backup
- **WHEN** group `cache` has `root_volume_type = "sbs_volume"` and `enable_backup_snapshot = true`
- **THEN** one block snapshot per server is planned and no instance snapshot

#### Scenario: Backup disabled
- **WHEN** no group enables backup
- **THEN** no snapshot is planned and `backup_snapshots` is empty
