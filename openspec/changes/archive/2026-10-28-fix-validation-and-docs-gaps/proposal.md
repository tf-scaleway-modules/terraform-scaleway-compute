## Why

Writing the `adopt-openspec` baseline surfaced nine suspected gaps between the README, the
inputs and the resources. Each was checked against the code and the provider schema
(`scaleway/scaleway` 2.86). Seven are real: documentation that describes behaviour that does
not exist, inputs that are accepted but silently ignored, and validations that only cover the
global rule variables. Two are not defects.

## What Changes

| # | Issue | Verified | Decision | Breaking? |
|---|-------|----------|----------|-----------|
| 1 | README documents `ignore_tags_changes` | True: no such variable | Doc fix: replace the paragraph with the accurate statement (tag drift cannot be ignored through an input) | No |
| 2 | README says timeouts apply to security groups | True: only servers (create/update/delete) and SBS volumes (create/delete) | Doc fix: README names the covered resources; spec states the scope | No |
| 3 | `instances[*].create_security_group` accepted, never read | True | Keep the attribute (removing it is major); add a `check` warning naming the groups and mark it ignored in the type comment | No |
| 4 | `private_networks[*].ip_address` accepted, never sent | True: `scaleway_instance_server.private_network` only has `pn_id` (+ computed `mac_address`, `pnic_id`, `status`, `zone`); a static IP needs IPAM plus `scaleway_instance_private_nic`, a different resource model | Keep the attribute; add a `check` warning; correct both descriptions that promised a static IP. Implementing static IPs is a feature, out of scope | No |
| 5 | Group-level rules and default policies bypass validation | True | Code fix: add `instances` validations for protocol, CIDR, port/port_range exclusivity and the two default policies, same rules as the global variables | No: rejects only values the provider or API refuses at apply time |
| 6 | CIDR check only tests the `a.b.c.d/n` shape | True: `999.0.0.0/99` passes | Code fix: also require `can(cidrhost(ip_range, 0))`, global and group level. IPv4 only, as before (no IPv6 is introduced) | No: such values already failed at apply time |
| 7 | `ssh_public_key` sensitive, not ephemeral; key not referenced by servers | Partly. `scaleway_iam_ssh_key` has no write-only argument, so `ephemeral` cannot be used. Scaleway scopes IAM SSH keys to the Project and pushes them to an Instance when it boots, so ordering the key before the servers (`depends_on`) is the correct dependency, not a bug. A public key is not a secret | Doc fix only: description and spec state the behaviour. `sensitive` is kept (harmless, removing it would only change plan output and gains nothing) | No |
| 8 | `security_group_id` ignored when `create_security_group = true` | True | `check` warning plus a clearer description | No |
| 9 | `external_volume_ids` precondition on the server skips `count = 0` | Not an issue: the rule is `count <= 1`, which `count = 0` satisfies, and a group with `count = 0` creates no server | Left unchanged | n/a |

New `check` blocks live in a new `checks.tf` (warnings only; they never fail a plan).

Inputs whose meaning is clarified (no type or default change): `instances`
(`create_security_group`, `private_networks[*].ip_address` documented as ignored),
`private_networks`, `security_group_id`, `ssh_public_key`.

State: nothing new lands in state. No new secret-bearing input (`terraform-security`).

## Semver

**Patch.** Fixes, descriptions and documentation (`terraform-versioning`); the new validations
reject only inputs that already failed at apply time; checks only warn. No input or output is
added, removed or retyped, no default changes, no resource address changes, no `moved` needed.

## Impact

- `variables.tf`, new `checks.tf`, `README.md`, `examples/complete/main.tf` (no ignored input).
- Specs: `input-validation`, `runtime-checks`, `ssh-keys`, `networking`, `resource-timeouts`.
- Tests: new runs in `tests/validations.tftest.hcl` and `tests/main.tftest.hcl` (checks).
- Standards applied: `terraform-versioning`, `terraform-variables`, `terraform-security`
  (guardrails as `check`), `terraform-testing`, `quality-production-readiness`.
