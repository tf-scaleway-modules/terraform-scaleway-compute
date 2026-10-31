## Context

See `proposal.md`. Provider `scaleway/scaleway` 2.89.0 changed no schema the module relies on
versus 2.86.0 (docs and `server.go` compared); the work is to expose three existing
`scaleway_instance_server` arguments. `required_version` (`>= 1.10.7`) and the provider
constraint (`~> 2.86`, resolves to 2.89.0) are unchanged.

## Goals / Non-Goals

**Goals**
- SBS root volumes (with IOPS) and deletion protection per instance group, with the same
  shape as the existing group attributes.
- Reject at plan time the combinations the provider/API cannot honour.

**Non-Goals**
- Raising the provider floor, security groups on private NICs, `srn` outputs, dual-stack IPs,
  filesystems, block snapshots for SBS roots: see the deferred table in `proposal.md`.

## Decisions

### Resources and arguments (provider version that introduced them)

| Resource | Argument | Introduced | Fed by |
|----------|----------|-----------|--------|
| `scaleway_instance_server.this` | `root_volume.volume_type = "sbs_volume"` | before 2.86.0 (present in the 2.86.0 docs) | `instances[*].root_volume_type` |
| `scaleway_instance_server.this` | `root_volume.sbs_iops` (Optional + Computed) | before 2.86.0; waits for the root SBS volume before applying IOPS since 2.88.0 | `instances[*].root_volume_sbs_iops` |
| `scaleway_instance_server.this` | `protected` (Optional, default `false`) | before 2.86.0 | `instances[*].enable_protection` |

No new resource and no new data source.

### Provider floor stays `~> 2.86`
`terraform-providers` / `terraform-versioning`: raise the floor only when an argument does not
exist in the old floor. All three exist in 2.86.0, so raising it would force a major bump for
no capability. Trade-off: on 2.86.x-2.87.x a first apply that sets `root_volume_sbs_iops`
can hit the race fixed in 2.88.0 (IOPS update before the root SBS volume is available). The
`~> 2.86` constraint resolves to 2.89.0 for any fresh lock file; the `root_volume_sbs_iops`
description and the README tell callers on an older lock to run `tofu init -upgrade`.

### Inputs (`terraform-variables`)
- `enable_protection = optional(bool, false)`: boolean with the `enable_` prefix; the default
  is the provider default, so no invented default.
- `root_volume_sbs_iops = optional(number)`: `null` means the API default (the provider
  attribute is Optional + Computed), the argument is only sent when set.
- `root_volume_type` keeps `l_ssd` and `b_ssd` (removing `b_ssd` would be breaking) and adds
  `sbs_volume`, the provider's name for an SBS root.
- Validations in the `instances` variable, each with an `error_message` naming the accepted
  values: root type enum; `root_volume_sbs_iops` only with `sbs_volume` and in `{5000, 15000}`
  (the SBS classes the module already offers for additional volumes); `enable_backup_snapshot`
  not with `sbs_volume`.
- Alternative rejected for the snapshot guard: also creating `scaleway_block_snapshot` for
  SBS roots. It adds a resource, an output shape and a snapshot lifecycle; a validation keeps
  this change small and honest. The guard is a `validation` (not a `check`) because the
  combination can never apply (`terraform-security`: validation when never acceptable).

### Wiring
`locals.tf` adds `root_volume_sbs_iops` and `enable_protection` to each `instances_flat` entry.
`main.tf` sets `protected = each.value.enable_protection` and
`sbs_iops = each.value.root_volume_sbs_iops` inside the existing `root_volume` block. No
`dynamic` block, no conditional, no `depends_on` change.

## Perpetual diff and state migration

- `protected`: the provider default is `false`; the module default is `false`; state already
  holds `false`. Empty plan after upgrade.
- `sbs_iops`: Optional + Computed. With `null`, Terraform keeps the value the API reports for
  an SBS root (and `null`/empty for `l_ssd`), so there is no diff. When set, config equals
  state after the first apply.
- `volume_type`: values already in use are unchanged. Changing an existing group from
  `l_ssd` to `sbs_volume` is not a supported in-place change (the provider documents that
  root volume updates may recreate the server): treat it as a replacement and say so in the
  README upgrade note.
- Migration for existing consumers: in-place, nothing to move, no `moved` block, no state
  surgery. `protected = true` on a live server is an in-place update; a protected server
  cannot be destroyed until `enable_protection` is set back to `false` and applied (intended).

## Risks / Trade-offs

- [Protected server blocks `tofu destroy`] -> intended; README documents the two-step
  unprotect-then-destroy, and the default stays `false`.
- [Older provider lock hits the 2.88.0 IOPS race] -> description + README note (`init -upgrade`);
  floor not raised (would be major).
- [`l_ssd` default root is unavailable on newer Instance types] -> unchanged default (changing
  it is major); `sbs_volume` is now available as an explicit choice.
- [SBS root excludes backup snapshots] -> validation message names the cause; block snapshots
  deferred.

## Migration Plan

1. Upgrade the module tag; `tofu init -upgrade` (resolves provider 2.89.0).
2. `tofu plan` shows no change for existing configurations.
3. Opt in per group with `enable_protection` or `root_volume_type = "sbs_volume"` for new groups.
4. Rollback: remove the attributes and apply (protection is lifted in place); revert the tag.
