## Context

`versions.tf` sets `required_version = ">= 1.10.7"` and `~> 2.89`; `examples/*/versions.tf` say `>= 1.10` and `~> 2.89`. `mise.toml` pins `opentofu = '1.11.6'` with no Terraform; `.gitlab/release.yml` validates with `ghcr.io/opentofu/opentofu:1.11.6` only. The pre-commit Terraform hooks (`terraform_fmt`, `terraform_docs`, `terraform_tflint`) carry no `--tf-path`. The outputs expose `id` and `name` but no Scaleway Resource Name.

## Goals / Non-Goals

**Goals:**
- Meet `terraform-providers` (one `>= 1.11.0` floor for both tools), `terraform-repo-mise` (exact OpenTofu and Terraform pins), `terraform-repo-gitlab-ci` (Terraform validation job in `create:release` needs) and `terraform-repo-precommit` (hooks run tofu).
- Expose `srn` where the provider has it, without new top-level outputs.

**Non-Goals:**
- No new input, resource, `moved` block or behaviour change; no `.tofu` file, no `language {}` block, nothing `terraform validate` rejects (none exists today).
- Not adding `terraform_validate`, `terraform_checkov` or `terraform_trivy` hooks, and not bumping the hook `rev` (v1.105.0): the store lists them, but the BRIEF scopes this change to `--tf-path`.
- No new GitHub job: the mirror workflows only get the new OpenTofu pin (they have no Terraform step).

## Decisions

1. **Core floor `>= 1.11.0`**, one constraint in `versions.tf` and both examples (`terraform-providers`). The module uses no feature beyond it. Major bump v4.0.0 (`terraform-versioning`).
2. **Provider `~> 2.93`** in `versions.tf` and both examples (the example constraint must equal the root's). `srn` was added by provider 2.93.0 to `scaleway_instance_server`, `scaleway_instance_security_group`, `scaleway_instance_volume`, `scaleway_instance_snapshot`, `scaleway_block_volume`, `scaleway_block_snapshot` (plus `scaleway_instance_placement_group`, `scaleway_instance_private_nic`, `scaleway_iam_ssh_key`). Verified in a scratch copy: `tofu providers schema -json` at 2.93.0 lists the `srn` attribute on all of them and not on `scaleway_instance_ip`. This is the "Raised floor" scenario of `terraform-providers`: the argument is `srn`, introduced in 2.93.0.
3. **`srn` goes into existing map outputs only**: `instances`, `instances_by_group` (it mirrors `instances`, so it gets the same key), `security_groups`, `volumes` (both the local and SBS branches) and `backup_snapshots` (both branches). Each is `srn = v.srn`, a computed read-only attribute: nothing is sent to the API, so there is no perpetual diff and the second plan stays empty. Existing state refreshes the attribute on the first plan after the provider upgrade (no replacement, no `moved` block). No `scaleway_instance_ip` entry: it has no `srn`, and `public_ips` stay lists of addresses.
4. **No new `placement_group_srn` / `ssh_key_srn` outputs.** Both are singletons already exposed as bare IDs (`placement_group_id` may be an external group's ID and null otherwise, so an `srn` would only exist for the created group and would have unclear semantics) and nothing asks for them. Adding them later is a minor change.
5. **Tests**: `mock_resource` generates random strings for unset computed attributes, so the `srn` of each mocked resource is set in `defaults` (instance server, security group, block and instance volume, instance and block snapshot) in `tests/main.tftest.hcl`, and the existing output runs assert the `srn` of each map entry. Other test files define their own mocks; they only need changes if a run asserts the output objects whole.
6. **CI** (`terraform-repo-gitlab-ci`): `validate:opentofu` image `1.13.10`; `validate:terraform` (`hashicorp/terraform:1.17.2`, same shape, root plus each `examples/*/`) placed right after it and added to `create:release` `needs:` after `validate:opentofu`. The pins equal `mise.toml` (`terraform-repo-mise`).
7. **GitHub mirror**: `tofu_version` in `ci.yml` and `release.yml` becomes `1.13.10`, equal to `mise.toml` (`terraform-repo-mise`, "Hooks and CI use the pinned tools"); no Terraform step exists, so none is added.
8. **Pre-commit**: add `args: [--hook-config=--tf-path=tofu]` to the three Terraform hooks so they keep using tofu now that `terraform` is installed (`terraform-repo-precommit`, "Terraform hooks run tofu").
9. **Specs**: `module-contract` states the floor and the provider constraint; deltas also cover the four output requirements that list their entry keys. The repo specs mention neither the toolchain nor CI jobs, so no other delta.
10. **Docs**: README prose and badges (Terraform badge `>=1.10`, provider badge `>=2.86`) name OpenTofu and Terraform >= 1.11.0 and provider >= 2.93, plus an upgrade note and an `srn` usage line; the README requirements table sits inside the terraform-docs markers and is regenerated, not edited. `AGENTS.md` names both tools and gains the `terraform init -backend=false && terraform validate` command. The config.yaml context line is updated. Stale-version grep: `1.10.0`, `1.10.7`, `1.11.6`, `v1.2.6`, `2.89`, `2.86`, `2.88` (the 2.88.0 README note about SBS IOPS stays accurate).

## Risks / Trade-offs

- Consumers on OpenTofu/Terraform 1.10 or provider < 2.93 are blocked: accepted, it is the major bump with an upgrade note.
- The provider floor `~> 2.93` also excludes 3.x; unchanged policy.
- The GitHub mirror has no Terraform validation job; the BRIEF forbids adding one.
- Raising OpenTofu to 1.13.10 may change `tofu fmt` output or tflint results; the apply step runs the full check list and reports as-is.
