## MODIFIED Requirements

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
