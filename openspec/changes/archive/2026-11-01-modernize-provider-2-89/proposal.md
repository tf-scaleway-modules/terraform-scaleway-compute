## Why

The module pins `scaleway/scaleway ~> 2.86` and was released as v2.2.0. Provider 2.89.0 (2026-10-27) adds the one capability the archived `update-provider-2-89` change had to defer because it needs a major: **security groups on Instance private NICs** (`scaleway_instance_private_nic.security_group_id`). Today private-network traffic of every server is unfiltered. A major release is allowed, so this change also pays down the debt that accumulated in v1-v2: the project lookup by name, dual SSH key inputs, flat prefixed security/placement variables, inputs that are accepted but ignored (with `check` warnings), a provider-removed root volume type (`b_ssd`), a deprecated placement argument, IPv4-only IP/rule handling and no backup for SBS root volumes.

## What Changes

### Adopted features

| # | Item | Resource / argument | Provider version | Module surface |
|---|------|--------------------|------------------|----------------|
| 1 | Security group on private NICs | `scaleway_instance_private_nic.security_group_id` and optional `server_id` | 2.89.0 | New group attribute `enable_private_nic_security_group` (default `false`): the NICs of the group use the security group resolved for its servers |
| 2 | Private NICs as resources | `scaleway_instance_private_nic` (`private_network_id`, `server_id`, `tags`, `private_ips`) replaces the inline `scaleway_instance_server.private_network` block | resource pre-2.86; `security_group_id` 2.89.0 | `private_networks` becomes a list of network IDs; private addresses are read from the NICs |
| 3 | Dual stack public IPs | `scaleway_instance_server.ip_ids` (replaces `ip_id`), one extra `scaleway_instance_ip` of type `routed_ipv6` | `ip_ids` pre-2.86, `ip_id` to `ip_ids` migration does not detach the IP (provider docs) | New group attribute `enable_ipv6` (default `false`); IPv6 CIDRs accepted in security group rules |
| 4 | Backup of SBS root volumes | `scaleway_block_snapshot` (`volume_id` = root volume ID) | pre-2.86 | `enable_backup_snapshot` now works with `root_volume_type = "sbs_volume"`; new output `backup_snapshots` |
| 5 | Group tags on every group resource | `tags` of volumes, public IPs, NICs, snapshots | pre-2.86 | Additional volumes and IPs carry `group:<group>` and the group `tags` (were global tags only) |

### Breaking changes

| # | Change | Consumer edit |
|---|--------|---------------|
| 1 | **BREAKING** `organization_id` and `project_name` removed, `scaleway_account_project` data source removed; new `project_id` (`null` = provider default project) | `project_id = "<uuid>"`. Use the v2 `project_id` output value: a different project replaces everything |
| 2 | **BREAKING** `zone` default `"fr-par-1"` becomes `null` (provider default zone) | Set `zone = "fr-par-1"` if the provider zone differs |
| 3 | **BREAKING** `create_ssh_key`, `ssh_public_key_file` removed; the key is created when `ssh_public_key` is set | `ssh_public_key = file("~/.ssh/id_ed25519.pub")`; drop `create_ssh_key` |
| 4 | **BREAKING** `create_security_group`, `security_group_id`, `inbound_default_policy`, `outbound_default_policy`, `stateful`, `inbound_rules`, `outbound_rules` collapse into `security_group` (`id` = existing shared group, otherwise one is created) | `security_group = { id = ... }` or `{ inbound_rules = [...] }` |
| 5 | **BREAKING** default `inbound_rules` is `[]` (was TCP 22 from `0.0.0.0/0`): secure default, nothing is world-open unless asked | Add `{ protocol = "TCP", port = 22, ip_range = "<cidr>" }` to `security_group.inbound_rules` |
| 6 | **BREAKING** `create_placement_group`, `placement_group_id`, `placement_group_policy_type`, `placement_group_policy_mode` collapse into `placement_group` (`null` none, `{}` create, `{ id }` existing); `policy_mode` is deprecated in the provider and dropped | `placement_group = {}` or `{ policy_type = "low_latency" }` or `{ id = "..." }` |
| 7 | **BREAKING** `private_networks` (global and per group) from `list(object({id, ip_address}))` to `list(string)`; `ip_address` was never applied | `private_networks = [pn.id]` |
| 8 | **BREAKING** global `public_ip_type` removed, becomes per group `public_ip_type`; value `nat` dropped (not an IP type in the provider docs) | Set `public_ip_type` on each group that does not use `routed_ipv4` |
| 9 | **BREAKING** group attributes `create_security_group`, `security_group_id`, `inbound_default_policy`, `outbound_default_policy`, `stateful`, `inbound_rules`, `outbound_rules` collapse into group `security_group`, same shape as the global one | `security_group = { id = ... }` or `{ inbound_rules = [...] }` |
| 10 | **BREAKING** `root_volume_type = "b_ssd"` rejected (the provider no longer supports it) | Use `l_ssd` or `sbs_volume` |
| 11 | **BREAKING** private NICs become `scaleway_instance_private_nic` resources: no `moved` path exists from an inline block | Import the NICs (`import` blocks in the root module) or detach, then upgrade: see the README upgrade section and `design.md` |
| 12 | **BREAKING** outputs `project_id`, `group_security_group_ids`, `block_volumes`, `public_ips`, `private_ips` removed; `volumes` now holds every additional volume; `instances[*]` and `instances_by_group[*]` replace `public_ip`/`private_ip` with `public_ips`/`private_ips` (lists of addresses) | Read `module.x.instances[k].public_ips`, `module.x.security_groups`, `module.x.volumes` |

### Simplifications

| Item | Result |
|------|--------|
| `data.tf`, `checks.tf` deleted | Three ignored-input warnings and the SSH key precondition disappear with the inputs they guarded |
| Dual SSH inputs and `create_ssh_key` | One `ssh_public_key` |
| Duplicated global/group rule validations | One validation set per rule list, same message family |
| `default_private_networks`, `public_ip_instances`, `ssh_public_key_content` locals | Removed |
| Seven flat security group variables, four flat placement variables | Two objects |
| `output.public_ips`, `output.private_ips`, `output.group_security_group_ids`, `output.block_volumes`, `output.project_id` | Removed; data is in `instances` / `security_groups` / `volumes` |

### Deferred / rejected

| Item | Provider version | Decision and reason |
|------|------------------|---------------------|
| Static private IP (`ipam_ip_ids`, `scaleway_ipam_ip`) | 2.89.0 | Rejected: one IPAM IP per server and network, no demand stated; Scaleway assigns a stable address per NIC. `ip_address` is removed rather than ignored |
| `scaleway_instance_private_nic` keyed by network ID | n/a | Rejected: IDs are unknown at plan time when the network is created in the same apply; keys are `<server key>-pn-<NN>` |
| `filesystems` (File Storage) | pre-2.86 | Rejected: separate product the module does not manage |
| `admin_password_encryption_ssh_key_id` | pre-2.86 | Rejected: Windows only, the module targets Linux images |
| `replace_on_type_change` | pre-2.86 | Rejected: the provider default (migrate in place) is the safer behaviour |
| `enable_dynamic_ip`, `boot_type`, `bootscript_id` (deprecated) | pre-2.86 | Rejected: dynamic IPs are legacy, `routed` IPs are the module's model |
| `scaleway_instance_security_group.enable_default_security = false` | pre-2.86 | Rejected: unblocks SMTP, a weaker default (`quality-security`) |
| `scaleway_instance_ip_reverse_dns` / `scaleway_instance_ip.reverse` | pre-2.86 | Rejected: needs a DNS zone per address; no demand |
| `root_volume.name`, `scaleway_block_volume.snapshot_id`, `scaleway_instance_image`, `scaleway_instance_user_data`, `scaleway_instance_template`, autoscaling | pre-2.86 | Rejected: other products or no demand (`quality-simplicity`) |
| `srn` attributes (private NIC, placement group, block volume/snapshot) | 2.87-2.89 | Rejected: computed only, no consumer need stated |
| `ip_id` kept next to `ip_ids` | n/a | Rejected: `ip_ids` covers both cases |
| Ephemeral / write-only arguments | 2.89.0 | Not applicable: the module sends no secret (`ssh_public_key` is public, `scaleway_iam_ssh_key` has no `*_wo`) |

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `module-contract`: provider floor, required inputs, defaults, project/zone resolution, outputs.
- `input-validation`: validation set reworked for the new objects, `b_ssd`, IPv6, `project_id`.
- `instances`: backup snapshots for SBS roots, group tags, private NICs removed from the server.
- `networking`: dual stack IPs, private NICs with optional security group, IP outputs.
- `security-groups`: `security_group` object, secure default, IPv6 rules, outputs.
- `placement-groups`: `placement_group` object.
- `ssh-keys`: single input, creation implied.
- `storage-volumes`: group tags, merged `volumes` output.
- `runtime-checks`: checks and SSH precondition removed.
- `resource-timeouts`: scope sentence names the new resources.

## Semver

**Major** (`terraform-versioning`): required inputs removed, inputs and outputs removed or retyped, defaults changed (`zone`, `inbound_rules`, `public_ip_type`), provider floor raised to `~> 2.89`, and a resource type change (`private_network` block to `scaleway_instance_private_nic`) with no `moved` path. The commit uses `feat!:` with a `BREAKING CHANGE` footer; the next release is **v3.0.0**.

Inputs whose type, default or meaning changes: `project_id` (new, replaces `organization_id` + `project_name`), `zone` (default `null`), `ssh_public_key` (creates the key), `security_group` (new object), `placement_group` (new object), `private_networks` (`list(string)`), `instances` (group `security_group`, `public_ip_type`, `enable_ipv6`, `enable_private_nic_security_group`, `private_networks`, `enable_backup_snapshot` now valid with SBS roots). Removed inputs: `organization_id`, `project_name`, `create_ssh_key`, `ssh_public_key_file`, `create_security_group`, `security_group_id`, `inbound_default_policy`, `outbound_default_policy`, `stateful`, `inbound_rules`, `outbound_rules`, `create_placement_group`, `placement_group_id`, `placement_group_policy_type`, `placement_group_policy_mode`, `public_ip_type`.
Outputs: removed `project_id`, `group_security_group_ids`, `block_volumes`, `public_ips`, `private_ips`; meaning changed `volumes`, `instances`, `instances_by_group`; new `backup_snapshots`. `required_version` stays `>= 1.10.7` (no write-only or ephemeral feature is used).

## State

- Unchanged addresses (no `moved` needed): `scaleway_instance_server.this`, `scaleway_instance_ip.this`, `scaleway_instance_security_group.{shared,group}`, `scaleway_instance_security_group_rules.{shared,group}`, `scaleway_instance_placement_group.this`, `scaleway_block_volume.this`, `scaleway_instance_volume.this`, `scaleway_instance_snapshot.this`, `scaleway_iam_ssh_key.this`.
- New in state: `scaleway_instance_private_nic.this`, `scaleway_instance_ip.ipv6`, `scaleway_block_snapshot.this`. Nothing secret: the SSH public key is public and was already stored.
- Removed from state: `data.scaleway_account_project.project`; the inline `private_network` blocks of the servers (replaced by NIC resources, see `design.md`).
- In-place updates on upgrade: tags of volumes and IPs (group tags added), `ip_id` to `ip_ids` on servers (no detach), and, if `inbound_rules` was not set explicitly, the removal of the default SSH rule.

## Impact

- Code: `versions.tf`, `variables.tf` (rewritten), `locals.tf`, `main.tf`, `network.tf`, `placement.tf`, `iam.tf`, `storage.tf`, `outputs.tf`; `data.tf` and `checks.tf` deleted.
- Docs: README upgrade section "Upgrading from v2 to v3", usage and security sections; terraform-docs block regenerated; `openspec/config.yaml` context refreshed at apply time.
- Examples: `examples/minimal`, `examples/complete` (+ their `versions.tf`).
- Specs: ten capabilities listed above.
- Tests: all four `tests/*.tftest.hcl` files change.
- Standards applied: `terraform-versioning`, `terraform-providers`, `terraform-variables`, `terraform-outputs`, `terraform-security` (open SSH default removed, NIC filtering), `terraform-testing`, `terraform-state`, `quality-simplicity`, `quality-security`, `quality-production-readiness`.
