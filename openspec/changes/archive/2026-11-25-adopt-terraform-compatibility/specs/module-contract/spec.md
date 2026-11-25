## MODIFIED Requirements

### Requirement: Supported tooling and provider
The module SHALL declare one `required_version = ">= 1.11.0"`, read by both OpenTofu and Terraform, and the single required provider `scaleway/scaleway` with version constraint `~> 2.93` in `versions.tf`; the examples SHALL declare the same constraints.

#### Scenario: Older tool version
- **WHEN** the module is initialised with a Terraform or OpenTofu older than 1.11.0
- **THEN** initialisation fails on the `required_version` constraint

#### Scenario: Either tool validates
- **WHEN** `tofu validate` or `terraform validate` runs in the module and in each example
- **THEN** both succeed

#### Scenario: Older provider
- **WHEN** the lock file pins `scaleway/scaleway` 2.92.0 or older
- **THEN** initialisation fails until `tofu init -upgrade` selects 2.93.0 or newer

### Requirement: Outputs
The module SHALL expose the outputs `ssh_key_id`, `shared_security_group_id`, `security_groups`, `placement_group_id`, `volumes`, `instances`, `instances_by_group` and `backup_snapshots`, each with a description, and none of them SHALL be marked sensitive.

#### Scenario: Instance outputs
- **WHEN** an instance group `web` has `count = 2`
- **THEN** `instances` has the keys `web-00` and `web-01`, each with `id`, `name`, `type`, `state`, `zone`, `srn`, `public_ips` and `private_ips` (lists of addresses, empty when none)

#### Scenario: Instances by group
- **WHEN** groups `web` and `db` exist
- **THEN** `instances_by_group` has the keys `web` and `db`, each mapping instance keys to `id`, `name`, `srn`, `public_ips` and `private_ips`

#### Scenario: Missing address
- **WHEN** an instance has no public or private IP
- **THEN** its `public_ips` or `private_ips` is an empty list
