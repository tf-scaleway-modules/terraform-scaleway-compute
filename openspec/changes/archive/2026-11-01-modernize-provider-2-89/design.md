## Context

v2.2.0 pins `~> 2.86` (resolves to 2.89.0). The archived `update-provider-2-89` change found no schema change between 2.86.0 and 2.89.0 for the resources in use and deferred everything that needed a major. Schema 2.89.0 was compared for the 8 resources the module manages and the adjacent Instance/Block resources (`scaleway_instance_private_nic`, `scaleway_block_snapshot`, `scaleway_instance_ip_reverse_dns`, `scaleway_instance_image`, `scaleway_ipam_ip`). Facts that drive the design:

- `scaleway_instance_private_nic.security_group_id` and optional `server_id`: 2.89.0. `ip_ids` is deprecated, `ipam_ip_ids` is the IPAM input.
- `scaleway_instance_server.private_network` is a list block (max 8), **not** computed, and the server read (`server.go`, `ph.set`) rewrites it from the API on every refresh, including NICs created by a separate resource.
- `scaleway_instance_server.ip_ids` and `ip_id` are both optional, not computed; docs state moving from `ip_id` to `ip_ids` does not detach the IP.
- `scaleway_instance_placement_group.policy_mode` is deprecated in the schema.
- The provider rejects `b_ssd` ("not supported anymore"); `scaleway_instance_ip.type` documents `routed_ipv4` and `routed_ipv6` only.
- `scaleway_instance_snapshot.type` accepts `l_ssd` only; `scaleway_block_snapshot.volume_id` takes the SBS volume ID.
- `scaleway_iam_ssh_key.public_key` has no write-only variant; no resource used here has a `*_wo` argument, so `required_version` stays `>= 1.10.7`.

## Goals / Non-Goals

**Goals**
- Provider floor `~> 2.89`; security groups on private NICs; dual stack; SBS root backup.
- Apply the cross-module conventions: `project_id`, optional `zone`, group tags everywhere, objects with `optional()` over flat prefixed variables.
- Remove every accepted-but-ignored input, dual input and deprecated argument.

**Non-Goals**
- Static private IPs, File Storage, reverse DNS, images, templates, autoscaling (see the rejected table in `proposal.md`).
- Changing the `<group>-<NN>` keys, resource names or the security group priority.

## Decisions

### Resources and arguments

| Resource | Argument | Introduced | Fed by |
|----------|----------|-----------|--------|
| `scaleway_instance_private_nic.this` (`for_each`) | `server_id`, `private_network_id`, `security_group_id`, `tags` | resource pre-2.86, `security_group_id` 2.89.0 | `private_networks`, `enable_private_nic_security_group` |
| `scaleway_instance_server.this` | `ip_ids` (replaces `ip_id`) | pre-2.86 | primary and IPv6 IP IDs, built with `concat` of one-element or empty lists (`compact` would turn the whole list unknown at plan time) |
| `scaleway_instance_server.this` | `lifecycle { ignore_changes = [private_network] }` | n/a | the NIC resources own the attachments |
| `scaleway_instance_ip.ipv6` (`for_each`) | `type = "routed_ipv6"` | pre-2.86 | `enable_ipv6` |
| `scaleway_block_snapshot.this` (`for_each`) | `volume_id = server.root_volume[0].volume_id` | pre-2.86 | `enable_backup_snapshot` with `sbs_volume` |
| `scaleway_instance_placement_group.this` | no `policy_mode` | n/a | `placement_group.policy_type` |
| `scaleway_instance_security_group_rules.*` | IPv6 `ip_range` | pre-2.86 (verify read-back, see risks) | rule lists |
| `scaleway_block_volume.this`, `scaleway_instance_volume.this` | `tags` with group tags | pre-2.86 | group `tags` |

No data source remains (`scaleway_account_project` removed). `project_id = var.project_id` and `zone = var.zone` are passed as is: `null` lets the provider default apply.

### Input contract (types)

```hcl
variable "project_id" { type = string, default = null }   # UUID validation
variable "zone"       { type = string, default = null }
variable "ssh_public_key" { type = string, default = null, sensitive = true }
variable "security_group" {
  type = object({
    id                      = optional(string)
    inbound_default_policy  = optional(string, "drop")
    outbound_default_policy = optional(string, "accept")
    stateful                = optional(bool, true)
    inbound_rules           = optional(list(object({ action = optional(string, "accept"), protocol = optional(string, "TCP"), port = optional(number), port_range = optional(string), ip_range = optional(string, "0.0.0.0/0") })), [])
    outbound_rules          = optional(list(object({ ... same ... })), [])
  })
  default = {}
}
variable "placement_group" {
  type    = object({ id = optional(string), policy_type = optional(string) })
  default = null
}
variable "private_networks" { type = list(string), default = [] }
```

Group attributes: `security_group = optional(object({ id, inbound_default_policy, outbound_default_policy, stateful, inbound_rules, outbound_rules }), {})` with every field optional and no default (null = inherit the global value); the object itself defaults to `{}` instead of `null` so `locals` read the fields without `try()` (`DEVIATION(terraform-variables)`), `public_ip_type = optional(string, "routed_ipv4")`, `enable_ipv6 = optional(bool, false)`, `enable_private_nic_security_group = optional(bool, false)`, `private_networks = optional(list(string), [])`. The global `security_group` keeps defaults in its type because it is the base the groups inherit from. `placement_group.policy_type` has no default so the module can reject `id` + `policy_type`; `locals` applies `coalesce(policy_type, "max_availability")`.

`placement_group = null` means none, `{}` creates, `{ id }` reuses. `security_group = {}` (default) creates the shared group, `{ id }` reuses one. The `security_group.id` and `inbound_rules`/`outbound_rules` exclusivity is kept (validation, no `check`).

`name` stays required: the module derives every name from it and `project:<name>` tags (convention: optional prefix is called `name`; here it is also the workload identity, so it keeps no default).

### Private NICs: why a resource, and how existing state migrates

`security_group_id` exists only on `scaleway_instance_private_nic`; the server block cannot carry it. Decision: always use NIC resources (one mechanism), keyed `<server key>-pn-<NN>`. Keys cannot be the network ID because the ID is unknown at plan time when the network is created in the same apply.

**Perpetual diff:** the server read repopulates `private_network`, so a server without the block would plan the removal of its NICs on every run. The server therefore sets `lifecycle { ignore_changes = [private_network] }` (static, as `ignore_changes` cannot be dynamic). NIC changes are then driven only by `scaleway_instance_private_nic`.

**Migration (no `moved` path):** a `moved` block cannot turn a nested block into a resource, and a module cannot declare `import` blocks for keys it cannot know. With `ignore_changes` the v3 plan does *not* detach the existing NICs, but creating the NIC resources would try to attach a second NIC on the same network. Two supported paths, both documented in the README upgrade section:
1. **No re-attach (recommended):** before the first v3 apply, add root-module `import` blocks, one per server and network: `import { to = module.compute.scaleway_instance_private_nic.this["web-00-pn-00"]; id = "<zone>/<server_id>/<nic_id>" }` (`tofu plan -generate-config-out` is not needed). The NIC keeps its MAC and private IP; the plan then shows an in-place update only if `enable_private_nic_security_group` or tags change.
2. **Re-attach:** on v2.2.0 apply `private_networks = []` (detaches the NICs), then upgrade and apply v3. Downtime on the private network, new MAC, and the private IP is released with the NIC and may differ.

Impact stated for consumers: servers without any private network are unaffected; a second plan after path 1 or 2 is empty.

### IP: primary stays at the same address

`scaleway_instance_ip.this[<server key>]` keeps its address (no `moved`). IPv6 uses a separate `scaleway_instance_ip.ipv6[<server key>]` rather than re-keying `this`, which would force a replacement of existing IPs (address loss). The server switches from `ip_id` to `ip_ids = concat([this.id], [ipv6.id])` (each part only when enabled): in place, no detach (provider docs). Both IP resources keep `create_before_destroy`.

### SBS root backup

`enable_backup_snapshot` stays one flag. `locals` splits servers by `root_volume_type`: `l_ssd` -> `scaleway_instance_snapshot.this` (address unchanged), `sbs_volume` -> `scaleway_block_snapshot.this`. Both named `<server>-snapshot`, tagged like the server; `backup_snapshots` output merges them as `{ id, name, type }` with `type = "instance"|"block"`.

### Security defaults

- Default `inbound_rules` becomes `[]`: the old default exposed SSH to `0.0.0.0/0` (`quality-security`, `terraform-security`). Consumers relying on it must list the rule; the upgrade section shows it.
- NIC filtering defaults to `false`: enabling it with the default `drop` policy would silently cut private traffic. Opt-in per group, documented with an example that lists the private CIDR rules.
- IPv6 CIDRs accepted in rules; `0.0.0.0/0` stays the default `ip_range` and does not open IPv6.

### Tags

`global_tags` (`terraform`, `managed`, `project:<name>` + `tags`) stay. Group resources (servers, IPs, volumes, NICs, snapshots) add `group:<group>` and the group's `tags`, `distinct`. Existing volumes and IPs get an in-place tag update.

### Outputs

`project_id`, `group_security_group_ids`, `block_volumes`, `public_ips`, `private_ips` are removed (derivable); `volumes` merges local and SBS; `instances[*]` returns `public_ips` and `private_ips` lists (dual stack and several networks make a single `[0]` address ambiguous); `backup_snapshots` is new. Private addresses come from the NIC resources' `private_ips` (the server attribute would be stale until refreshed after a NIC attach).

### Alternatives considered

| Decision | Alternative | Why not |
|----------|-------------|---------|
| NIC resources only | Keep the inline block, add NICs only when a SG is wanted | Two mechanisms, still needs `ignore_changes`, and the server block cannot be switched per group without replacing NICs |
| `private_networks = list(string)` | Keep objects with `apply_security_group` per network | A per-network flag is speculative (`quality-simplicity`); the group flag covers the need |
| `this` + `ipv6` IP resources | Re-key `this` by `<server>-<type>` | Forces replacement of every existing IP |
| Drop `b_ssd` and `nat` | Keep them | The provider rejects `b_ssd` and the docs list no `nat` type |
| Keep `count` on singleton resources (shared SG, placement group, SSH key) | `for_each` | Same resource address, no state move for a 0/1 singleton |
| SSH key condition `nonsensitive(var.ssh_public_key != null)` | Keep `create_ssh_key` | A second input that must agree with the key; `nonsensitive` of a null test leaks nothing |
| Delete `checks.tf` | Keep a check for NIC flag without networks | The flag without networks is a harmless no-op |
| `required_version` stays `>= 1.10.7` | Raise to 1.11 | No write-only or ephemeral feature is used (`terraform-providers`) |

## Risks / Trade-offs

- **NIC migration** needs a manual step per server and network: documented, with both paths; verified in a real account (see tasks, group 8).
- **IPv6 rule read-back**: if the API normalises an IPv6 `ip_range` differently, the rules resource shows a perpetual diff. Real-account check; if it fails, restrict IPv6 to a documented form instead of dropping the feature.
- **NIC security group support** may depend on the Instance type or image; verify on `DEV1-S` and a current type; unsupported combinations surface as an API error at apply.
- **`ip_ids` switch**: documented as non-detaching; verify the second plan is empty.
- **Sensitive `count`**: confirmed by the unit test `ssh_key_created_from_sensitive_public_key` on the pinned OpenTofu: `count = nonsensitive(var.ssh_public_key != null) ? 1 : 0` works, no fallback needed.
- **Mock limits**: `mock_provider` cannot fill computed blocks (`public_ips`, `private_ips`) nor show provider-default `project_id`/`zone` as null (computed attributes are mocked), so those shapes are checked on empty lists/inputs in unit tests and fully in the real-account group.
- **Project/zone defaults**: `project_id = null` or `zone = null` resolve to the provider's values; if they differ from the v2 values, every resource is replaced. The upgrade section says to set both explicitly first.

## Migration Plan

1. Pin the v2 values: note the v2 `project_id` output and the zone.
2. Edit the call to the v3 inputs; run `tofu plan`: expected diffs are tag updates, `ip_id` to `ip_ids`, default rule removal, new NIC resources (create) and no replacement.
3. Add the NIC `import` blocks (path 1) or apply `private_networks = []` on v2.2.0 first (path 2).
4. Apply; run `tofu plan` again: it must be empty.
5. Roll back: pin the previous tag; v3-only resources (`ipv6` IPs, block snapshots, NICs created fresh) must be destroyed first.
