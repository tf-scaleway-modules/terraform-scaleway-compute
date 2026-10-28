## ADDED Requirements

### Requirement: Additional volumes per server
The module SHALL create each entry of a group's `additional_volumes` once per server of the group, named `<server name>-vol-<NN>` (two-digit index in list order), tagged with the global tags, and attach it to that server.

#### Scenario: Two servers, one volume
- **WHEN** group `db` has `count = 2` and one additional volume
- **THEN** two volumes are planned, named `<name>-db-00-vol-00` and `<name>-db-01-vol-00`

### Requirement: SBS block volumes
A volume whose `type` starts with `sbs_` SHALL be a `scaleway_block_volume` of `size_gb` GB whose IOPS are the volume's `iops` when set, else 15000 for `sbs_15k` and 5000 otherwise.

#### Scenario: Default IOPS
- **WHEN** a volume has `type = "sbs_5k"` and no `iops`
- **THEN** the block volume has 5000 IOPS

#### Scenario: 15k class
- **WHEN** a volume has `type = "sbs_15k"` and no `iops`
- **THEN** the block volume has 15000 IOPS

#### Scenario: Explicit IOPS
- **WHEN** a volume has `type = "sbs_5k"` and `iops = 7000`
- **THEN** the block volume has 7000 IOPS

### Requirement: Local volumes
A volume of type `l_ssd` SHALL be a `scaleway_instance_volume` of `size_gb` GB.

#### Scenario: Local volume
- **WHEN** a volume has `type = "l_ssd"`
- **THEN** an instance volume is planned and no block volume is planned for it

### Requirement: External volume attachment
The module SHALL attach the volumes listed in a group's `external_volume_ids` to its servers in addition to the volumes it creates.

#### Scenario: External volume
- **WHEN** a group with `count = 1` sets `external_volume_ids = ["fr-par-1/<id>"]`
- **THEN** the server has that volume among its additional volumes and the module creates no volume for it

### Requirement: Volume outputs
The module SHALL output `volumes` (local volumes) and `block_volumes` (SBS volumes) as maps of volume key `<server key>-vol-<NN>` to `{ id, name, type }` with `type` equal to `local` or `sbs`.

#### Scenario: Mixed volumes
- **WHEN** a server has one `l_ssd` and one `sbs_5k` volume
- **THEN** `volumes` has one entry of type `local` and `block_volumes` one entry of type `sbs`
