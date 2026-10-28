# instances Specification

## Purpose
Expansion of instance groups into Scaleway servers: naming, attributes, tags, user data / cloud-init and backup snapshots.

## Requirements

### Requirement: Instance groups expanded to servers
The module SHALL create one `scaleway_instance_server` per instance of every group, keyed `<group>-<NN>` (two-digit zero-padded index starting at `00`) and named `<name>-<group>-<NN>`, in `zone` and in the resolved project; a group with `count = 0` SHALL create no server.

#### Scenario: Group of three
- **WHEN** `name = "app"` and `instances = { web = { count = 3, instance_type = "DEV1-S" } }`
- **THEN** three servers are planned, named `app-web-00`, `app-web-01` and `app-web-02`

#### Scenario: Several groups
- **WHEN** group `backend` has `count = 2` and group `frontend` has `count = 1`
- **THEN** three servers are planned

#### Scenario: Empty group
- **WHEN** a group has `count = 0`
- **THEN** no server is planned for that group

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

### Requirement: Instance tags
Each server SHALL be tagged with the global tags, `group:<group>` and the group's `tags`, without duplicates.

#### Scenario: Group tag
- **WHEN** a group `web` sets `tags = ["api"]` and `tags = ["prod"]` is set globally
- **THEN** its servers carry `terraform`, `managed`, `project:<name>`, `prod`, `group:web` and `api`

### Requirement: User data and cloud-init
The module SHALL send a group's `cloud_init` as the `cloud-init` key of the server `user_data`, merged over the group's `user_data` map; when `cloud_init` is null the server SHALL receive `user_data` as is, or no user data when the map is empty.

#### Scenario: Cloud-init only
- **WHEN** a group sets `cloud_init = "#cloud-config\n..."` and no `user_data`
- **THEN** the server user data has the single key `cloud-init`

#### Scenario: Cloud-init and user data
- **WHEN** a group sets `cloud_init` and `user_data = { foo = "bar" }`
- **THEN** the server user data has the keys `cloud-init` and `foo`

#### Scenario: Neither
- **WHEN** a group sets neither
- **THEN** the server has no user data

### Requirement: Backup snapshots
The module SHALL create one `scaleway_instance_snapshot` of the root volume, named `<server name>-snapshot`, for each server of a group with `enable_backup_snapshot = true`, and none otherwise.

#### Scenario: Backup enabled
- **WHEN** group `db` has `count = 2` and `enable_backup_snapshot = true`
- **THEN** two snapshots are planned, keyed like the servers

#### Scenario: Backup disabled
- **WHEN** no group enables backup
- **THEN** no snapshot is planned

### Requirement: Server deletion protection
The module SHALL protect the servers of a group against accidental deletion through the Scaleway API when the group sets `enable_protection = true`, and SHALL leave them unprotected otherwise.

#### Scenario: Protection enabled
- **WHEN** a group sets `enable_protection = true`
- **THEN** its servers are planned with deletion protection on

#### Scenario: Default
- **WHEN** a group does not set `enable_protection`
- **THEN** its servers are unprotected and an upgraded configuration shows no change
