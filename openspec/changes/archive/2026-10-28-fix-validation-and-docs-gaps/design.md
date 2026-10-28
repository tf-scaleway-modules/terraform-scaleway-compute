## Context

All fixes stay inside the existing resources. Provider `scaleway/scaleway` ~> 2.86 is
unchanged, `required_version` is unchanged.

## Decisions

- **Warn, do not break, for ignored inputs (3, 4, 8).** Removing `create_security_group` or
  `ip_address`, or rejecting configurations that currently plan, would be major or would break
  working callers. `check` blocks (`terraform-security`, guardrails) report the ignored value
  at plan time without failing; the next major release can remove the attributes.
- **No static private IP (4).** `scaleway_instance_server.private_network` exposes only
  `pn_id`. A fixed address would need `scaleway_ipam_ip` and `scaleway_instance_private_nic`
  and a different attachment model; that is a feature and a state migration, not a fix.
- **Validation parity (5, 6).** Group-level rules reuse the global conditions, evaluated over
  `concat(coalesce(inbound_rules, []), coalesce(outbound_rules, []))` of every group, in the
  `instances` variable. CIDR is `can(cidrhost(ip_range, 0)) && !strcontains(ip_range, ":")`:
  `cidrhost` rejects `999.0.0.0/99`; the `:` test keeps IPv4-only behaviour, so nothing that
  was rejected before is accepted now. Group default policies are checked with `contains`
  when non-null.
- **SSH key (7).** `scaleway_iam_ssh_key.public_key` has no `_wo` variant, so `ephemeral`
  would make the module unusable; `sensitive` stays. IAM SSH keys are Project-scoped and
  copied to an Instance at boot, hence the existing `depends_on` (key exists before first
  boot); the description says the key applies to every Instance of the Project.
- **No perpetual diff:** no resource argument changes, so plans stay empty after apply and
  state needs no migration.

## Risks

- A configuration with an invalid group-level protocol, CIDR, port pair or default policy now
  fails at plan instead of apply. Such a configuration could not be applied before.
