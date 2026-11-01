# module-contract Specification

## Purpose
Cross-cutting contract of the module: tooling and provider constraints, required inputs and defaults, naming and tags, project resolution and outputs.

## Requirements

### Requirement: Supported tooling and provider
The module SHALL declare `required_version = ">= 1.10.7"` and the single required provider `scaleway/scaleway` with version constraint `~> 2.89` in `versions.tf`.

#### Scenario: Older tool version
- **WHEN** the module is initialised with a Terraform/OpenTofu older than 1.10.7
- **THEN** initialisation fails on the `required_version` constraint

#### Scenario: Older provider
- **WHEN** the lock file pins `scaleway/scaleway` 2.88.0 or older
- **THEN** initialisation fails until `tofu init -upgrade` selects 2.89.0 or newer

### Requirement: No provider or backend configuration
The module SHALL NOT contain a `provider` block or a `backend` block; the caller configures the Scaleway provider and the state backend.

#### Scenario: Caller supplies the provider
- **WHEN** the module is called from a root module that configures `provider "scaleway"`
- **THEN** every resource of the module uses that provider configuration

### Requirement: Required inputs
The module SHALL require `name` (string) and `instances` (map of instance group objects); every other input SHALL be optional.

#### Scenario: Required input omitted
- **WHEN** the module is called without `instances`
- **THEN** the plan fails because the argument is required

#### Scenario: Minimal call
- **WHEN** only `name` and `instances` are set
- **THEN** the plan succeeds in the provider's default project and zone

### Requirement: Instance group required attributes
Each `instances` entry SHALL require `count` and `instance_type`; its other attributes SHALL be optional.

#### Scenario: Missing instance type
- **WHEN** a group sets `count = 1` without `instance_type`
- **THEN** the plan fails because the attribute is required

### Requirement: Instance group defaults
Each `instances` entry SHALL default `image = "ubuntu_noble"`, `root_volume_size_gb = 20`, `root_volume_type = "l_ssd"`, `state = "started"`, `create_public_ip = true`, `public_ip_type = "routed_ipv4"`, and `enable_ipv6`, `enable_backup_snapshot`, `enable_protection` and `enable_private_nic_security_group` to `false`; `tags`, `private_networks`, `additional_volumes` and `external_volume_ids` to `[]`; `user_data` to `{}`.

#### Scenario: Group with defaults
- **WHEN** `instances = { web = { count = 1, instance_type = "DEV1-S" } }`
- **THEN** the server uses image `ubuntu_noble`, a 20 GB `l_ssd` root volume, state `started`, is unprotected and gets one `routed_ipv4` public IP

### Requirement: Instance group optional overrides
Each `instances` entry SHALL leave `cloud_init`, `root_volume_sbs_iops` and `placement_group_id` null and `security_group` empty (every field null) by default, which selects the global value or the provider default.

#### Scenario: Global values apply
- **WHEN** a group sets none of these attributes
- **THEN** its servers use the shared security group and the shared placement group, and no root volume IOPS is requested

### Requirement: Resource naming and tags
The module SHALL prefix every resource name with `name` and SHALL tag the resources it tags with `terraform`, `managed` and `project:<name>`, followed by the entries of `tags` without duplicates.

#### Scenario: Global tags
- **WHEN** `name = "app"` and `tags = ["prod"]`
- **THEN** the shared security group carries the tags `terraform`, `managed`, `project:app` and `prod`

### Requirement: Outputs
The module SHALL expose the outputs `ssh_key_id`, `shared_security_group_id`, `security_groups`, `placement_group_id`, `volumes`, `instances`, `instances_by_group` and `backup_snapshots`, each with a description, and none of them SHALL be marked sensitive.

#### Scenario: Instance outputs
- **WHEN** an instance group `web` has `count = 2`
- **THEN** `instances` has the keys `web-00` and `web-01`, each with `id`, `name`, `type`, `state`, `zone`, `public_ips` and `private_ips` (lists of addresses, empty when none)

#### Scenario: Instances by group
- **WHEN** groups `web` and `db` exist
- **THEN** `instances_by_group` has the keys `web` and `db`, each mapping instance keys to `id`, `name`, `public_ips` and `private_ips`

#### Scenario: Missing address
- **WHEN** an instance has no public or private IP
- **THEN** its `public_ips` or `private_ips` is an empty list

### Requirement: Input defaults
The module SHALL default `project_id = null`, `zone = null`, `tags = []`, `ssh_public_key = null` (sensitive), `security_group = {}` (a shared group is created, policies `drop` inbound and `accept` outbound, `stateful = true`, no rules), `placement_group = null`, `private_networks = []` and `timeouts = {}`.

#### Scenario: Minimal call
- **WHEN** only `name` and `instances` are set
- **THEN** the plan creates a shared security group dropping all inbound traffic, no SSH key, no placement group and no private NIC

### Requirement: Project and zone resolution
The module SHALL create every resource in `project_id` and `zone` when they are set, otherwise in the provider's default project and zone, and SHALL NOT read the account project data source.

#### Scenario: Provider defaults
- **WHEN** `project_id` and `zone` are null
- **THEN** the resources set no `project_id` and no `zone` and take the provider configuration

#### Scenario: Explicit project
- **WHEN** `project_id = "11111110-d164-47ec-8d04-111111111111"`
- **THEN** every resource is planned in that project
