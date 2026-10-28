# module-contract Specification

## Purpose
Cross-cutting contract of the module: tooling and provider constraints, required inputs and defaults, naming and tags, project resolution and outputs.

## Requirements

### Requirement: Supported tooling and provider
The module SHALL declare `required_version = ">= 1.10.7"` and the single required provider `scaleway/scaleway` with version constraint `~> 2.86` in `versions.tf`.

#### Scenario: Older tool version
- **WHEN** the module is initialised with a Terraform/OpenTofu older than 1.10.7
- **THEN** initialisation fails on the `required_version` constraint

### Requirement: No provider or backend configuration
The module SHALL NOT contain a `provider` block or a `backend` block; the caller configures the Scaleway provider and the state backend.

#### Scenario: Caller supplies the provider
- **WHEN** the module is called from a root module that configures `provider "scaleway"`
- **THEN** every resource of the module uses that provider configuration

### Requirement: Required inputs
The module SHALL require `organization_id` (string), `project_name` (string), `name` (string) and `instances` (map of instance group objects); every other input SHALL be optional.

#### Scenario: Required input omitted
- **WHEN** the module is called without `instances`
- **THEN** the plan fails because the argument is required

### Requirement: Placement, network and timeout input defaults
The module SHALL default `create_placement_group = false`, `placement_group_id = null`, `placement_group_policy_type = "max_availability"`, `placement_group_policy_mode = null`, `private_networks = []`, `public_ip_type = "routed_ipv4"`, `timeouts = {}`, `zone = "fr-par-1"` and `tags = []`.

#### Scenario: Minimal call
- **WHEN** only the four required inputs are set
- **THEN** the plan uses zone `fr-par-1`, creates no placement group and gives public IPs of type `routed_ipv4`

### Requirement: Security and SSH input defaults
The module SHALL default `create_ssh_key = false`, `ssh_public_key = null` (sensitive), `ssh_public_key_file = null`, `create_security_group = true`, `security_group_id = null`, `inbound_default_policy = "drop"`, `outbound_default_policy = "accept"`, `stateful = true`, `inbound_rules = [{ protocol = "TCP", port = 22, ip_range = "0.0.0.0/0" }]` and `outbound_rules = []`.

#### Scenario: Minimal call
- **WHEN** only the four required inputs are set
- **THEN** the plan creates a shared security group dropping inbound traffic except TCP 22 from `0.0.0.0/0`, and no SSH key

### Requirement: Instance group required attributes
Each `instances` entry SHALL require `count` and `instance_type`; its other attributes SHALL be optional.

#### Scenario: Missing instance type
- **WHEN** a group sets `count = 1` without `instance_type`
- **THEN** the plan fails because the attribute is required

### Requirement: Instance group defaults
Each `instances` entry SHALL default `image = "ubuntu_noble"`, `root_volume_size_gb = 20`, `root_volume_type = "l_ssd"`, `state = "started"`, `create_public_ip = true`, `enable_backup_snapshot = false`, `enable_protection = false`, and SHALL default `tags`, `private_networks`, `additional_volumes` and `external_volume_ids` to `[]` and `user_data` to `{}`.

#### Scenario: Group with defaults
- **WHEN** `instances = { web = { count = 1, instance_type = "DEV1-S" } }`
- **THEN** the server uses image `ubuntu_noble`, a 20 GB `l_ssd` root volume, state `started`, is unprotected and gets a public IP

### Requirement: Instance group optional overrides
Each `instances` entry SHALL leave `cloud_init`, `root_volume_sbs_iops`, `security_group_id`, `inbound_default_policy`, `outbound_default_policy`, `stateful`, `inbound_rules`, `outbound_rules` and `placement_group_id` null by default, which selects the global value or the provider default.

#### Scenario: Global values apply
- **WHEN** a group sets none of these attributes
- **THEN** its servers use the shared security group and the shared placement group, and no root volume IOPS is requested

### Requirement: Resource naming and tags
The module SHALL prefix every resource name with `name` and SHALL tag the resources it tags with `terraform`, `managed` and `project:<name>`, followed by the entries of `tags` without duplicates.

#### Scenario: Global tags
- **WHEN** `name = "app"` and `tags = ["prod"]`
- **THEN** the shared security group carries the tags `terraform`, `managed`, `project:app` and `prod`

### Requirement: Project resolution
The module SHALL look up the Scaleway project by `project_name` and `organization_id` through the `scaleway_account_project` data source and create every resource in that project.

#### Scenario: Project ID output
- **WHEN** the plan is applied
- **THEN** the `project_id` output equals the ID of the project found by name in the organization

### Requirement: Outputs
The module SHALL expose the outputs `project_id`, `ssh_key_id`, `shared_security_group_id`, `group_security_group_ids`, `security_groups`, `placement_group_id`, `volumes`, `block_volumes`, `instances`, `instances_by_group`, `public_ips` and `private_ips`, each with a description, and none of them SHALL be marked sensitive.

#### Scenario: Instance outputs
- **WHEN** an instance group `web` has `count = 2`
- **THEN** `instances` has the keys `web-00` and `web-01`, each with `id`, `name`, `type`, `state`, `zone`, `public_ip` and `private_ip`

#### Scenario: Instances by group
- **WHEN** groups `web` and `db` exist
- **THEN** `instances_by_group` has the keys `web` and `db`, each mapping instance keys to `id`, `name`, `public_ip` and `private_ip`

#### Scenario: Missing address
- **WHEN** an instance has no public or private IP
- **THEN** its entry in `public_ips` or `private_ips` is `null`
