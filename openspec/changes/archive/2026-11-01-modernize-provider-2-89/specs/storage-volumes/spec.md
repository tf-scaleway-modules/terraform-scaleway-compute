## MODIFIED Requirements

### Requirement: Additional volumes per server
The module SHALL create each entry of a group's `additional_volumes` once per server of the group, named `<server name>-vol-<NN>` (two-digit index in list order), tagged with the global tags, `group:<group>` and the group's `tags`, and attach it to that server.

#### Scenario: Two servers, one volume
- **WHEN** group `db` has `count = 2` and one additional volume
- **THEN** two volumes are planned, named `<name>-db-00-vol-00` and `<name>-db-01-vol-00`, tagged `group:db`

### Requirement: Volume outputs
The module SHALL output `volumes` as a map of volume key `<server key>-vol-<NN>` to `{ id, name, type }` for every additional volume the module creates, with `type` equal to `local` or `sbs`.

#### Scenario: Mixed volumes
- **WHEN** a server has one `l_ssd` and one `sbs_5k` volume
- **THEN** `volumes` has one entry of type `local` and one of type `sbs`
