## Why

Provider `scaleway/scaleway` 2.89.0 (2026-10-27) is out and the module pins `~> 2.86`. A
gap analysis of every resource the module manages, comparing the 2.86.0 and 2.89.0 provider
docs and the 2.89.0 server source, shows that **nothing the module uses changed its schema
between 2.86.0 and 2.89.0** except additive computed attributes the module does not read.
The real opportunity is two long-standing server arguments the module never exposed, one of
which (`root_volume.sbs_iops`) only became reliable in 2.88.0. Modern Instance types default
to an SBS root volume, yet the module can only create `l_ssd` / `b_ssd` roots and cannot protect
a production server from accidental API deletion.

## What Changes

Adopted (all exist in provider 2.86.0, so the floor stays `~> 2.86`, which already resolves to 2.89.0):

| # | Item | Provider argument | Introduced | Module surface |
|---|------|-------------------|------------|----------------|
| 1 | Create the root volume on SBS | `scaleway_instance_server.root_volume.volume_type = "sbs_volume"` | before 2.86 | `instances[*].root_volume_type` also accepts `sbs_volume` (`l_ssd` and `b_ssd` stay accepted) |
| 2 | Root volume IOPS | `scaleway_instance_server.root_volume.sbs_iops` | before 2.86; ordering bug fixed in 2.88.0 (instance waits for the root SBS volume before applying IOPS) | new optional `instances[*].root_volume_sbs_iops` (`5000` or `15000`), default `null` (API default); only valid with `root_volume_type = "sbs_volume"` |
| 3 | Deletion protection | `scaleway_instance_server.protected` | before 2.86 | new optional `instances[*].enable_protection`, default `false` (provider default) |

Guards that come with #1 and #2 (they reject only combinations the API or provider cannot honour):

- `root_volume_sbs_iops` set while `root_volume_type != "sbs_volume"` is rejected.
- `enable_backup_snapshot = true` with `root_volume_type = "sbs_volume"` is rejected:
  `scaleway_instance_snapshot` only snapshots `l_ssd` volumes (its `type` accepts only `l_ssd`), and
  an SBS root needs `scaleway_block_snapshot`, a different resource and output shape (deferred).

Not changed: `versions.tf` (`~> 2.86`), `required_version`, every default, every existing
output, every resource address.

### Deferred / rejected (gap analysis)

| Item | Provider version | Decision and reason |
|------|------------------|---------------------|
| Security groups on private NICs: `scaleway_instance_private_nic.security_group_id`, optional `server_id` | 2.89.0 | **Deferred.** Needs the floor raised to `~> 2.89` (major) and replacing the inline `private_network` block with `scaleway_instance_private_nic` resources: a NIC detach/re-attach per server (connectivity loss, new MAC and possibly a new private IP) plus state migration with no `moved` path from an inline block. Cost and risk exceed the value; revisit with a dedicated major release |
| `srn` attributes on placement group (2.88.0), private NIC, `data.scaleway_account_project` (2.87.0) | 2.87-2.88 | **Deferred.** Computed only, raising the floor (major) to expose them as outputs is not worth it; no consumer need stated |
| `scaleway_block_volume.srn`, other `srn` | pre-2.86 | Deferred: outputs would grow with no stated consumer |
| Instance keeps `public_ips` in sync with `ip_ids` | 2.84.0 fix | Already included by the current floor; nothing to do |
| `ip_ids` (several IPs, dual stack IPv4 + IPv6) | pre-2.86 | Deferred: needs a second IP resource per server and new outputs; a feature of its own |
| `filesystems` (Scaleway File Storage) | pre-2.86 | Deferred: niche, depends on a separate product the module does not manage |
| `admin_password_encryption_ssh_key_id` | pre-2.86 | Rejected: only for images that need an admin password (Windows); the module targets Linux images |
| `replace_on_type_change` | pre-2.86 | Deferred: the provider default (migrate in place) is the safer behaviour |
| `scaleway_instance_security_group.enable_default_security = false` | pre-2.86 | Rejected: unblocks SMTP, a weaker secure default (`terraform-security`); the provider default stays |
| `root_volume.name`, `block_volume.snapshot_id`, `scaleway_instance_ip.reverse` | pre-2.86 | Rejected: no demand, would grow `instances` for little value |
| Static private IP (`ip_address`) | n/a | Unchanged: still ignored with a check warning (see archived `fix-validation-and-docs-gaps`) |

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `instances`: root volume on SBS with optional IOPS; server deletion protection.
- `input-validation`: root volume type accepts `sbs_volume`; IOPS and backup-snapshot guards.
- `module-contract`: new group attributes and their defaults.

## Semver

**Minor** (`terraform-versioning`): new optional attributes with defaults inside the existing
`instances` map input and one value added to an existing enum. The provider floor is **not**
raised because every adopted argument already exists in 2.86.0 (a raised floor would be a
major bump). No input or output is removed, renamed or retyped; no default changes.

Inputs whose type or meaning changes: `instances` only (three new optional attributes;
`root_volume_type` accepts one more value). No outputs change.

## State

In-place only. `protected` `false` and an unset `sbs_iops` equal the provider defaults, so
existing servers show an empty plan after upgrade. Nothing new lands in state beyond the two
server arguments; no secret-bearing input is added (`terraform-security`).

## Impact

- `variables.tf` (`instances` type and validations), `main.tf` (`scaleway_instance_server.this`),
  `locals.tf` (flatten the three attributes), `README.md` (terraform-docs block, usage note on
  SBS roots and the 2.88 fix), `examples/complete/main.tf`.
- Specs: `instances`, `input-validation`, `module-contract`.
- Tests: new runs in `tests/instance_flattening.tftest.hcl` and `tests/validations.tftest.hcl`.
- Standards applied: `terraform-versioning`, `terraform-providers` (floor decision),
  `terraform-variables` (boolean prefix `enable_`, `null` = provider default, validation per
  enum), `terraform-testing`, `terraform-security` (insecure `enable_default_security`
  rejected), `quality-simplicity`, `quality-production-readiness`.
