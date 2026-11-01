## MODIFIED Requirements

### Requirement: Instance groups expanded to servers
The module SHALL create one `scaleway_instance_server` per instance of every group, keyed `<group>-<NN>` (two-digit zero-padded index starting at `00`) and named `<name>-<group>-<NN>`, in `zone` and `project_id` (provider defaults when null); a group with `count = 0` SHALL create no server.

#### Scenario: Group of three
- **WHEN** `name = "app"` and `instances = { web = { count = 3, instance_type = "DEV1-S" } }`
- **THEN** three servers are planned, named `app-web-00`, `app-web-01` and `app-web-02`

#### Scenario: Several groups
- **WHEN** group `backend` has `count = 2` and group `frontend` has `count = 1`
- **THEN** three servers are planned

#### Scenario: Empty group
- **WHEN** a group has `count = 0`
- **THEN** no server is planned for that group

### Requirement: Backup snapshots
For each server of a group with `enable_backup_snapshot = true`, the module SHALL snapshot the root volume as `<server name>-snapshot`: a `scaleway_instance_snapshot` for an `l_ssd` root, a `scaleway_block_snapshot` for an `sbs_volume` root; no snapshot otherwise. The `backup_snapshots` output SHALL list them by server key.

#### Scenario: Backup enabled
- **WHEN** group `db` has `count = 2`, `root_volume_type = "l_ssd"` and `enable_backup_snapshot = true`
- **THEN** two instance snapshots are planned, keyed like the servers

#### Scenario: SBS root backup
- **WHEN** group `cache` has `root_volume_type = "sbs_volume"` and `enable_backup_snapshot = true`
- **THEN** one block snapshot per server is planned and no instance snapshot

#### Scenario: Backup disabled
- **WHEN** no group enables backup
- **THEN** no snapshot is planned and `backup_snapshots` is empty
