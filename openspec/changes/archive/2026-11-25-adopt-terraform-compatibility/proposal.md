## Why

The `terraform` standards store v2.1.0 requires one `required_version >= 1.11.0` read by both OpenTofu and Terraform, a pinned OpenTofu and Terraform toolchain, a CI job that validates with Terraform too, and tofu-pinned pre-commit hooks (`terraform-providers`, `terraform-module-structure`, `terraform-repo-gitlab-ci`, `terraform-repo-mise`, `terraform-repo-precommit`). This module declares `>= 1.10.7`, pins `opentofu = '1.11.6'` and validates with OpenTofu only. Provider 2.93.0 also added the Scaleway Resource Name (`srn`) to the instance, block and IAM SSH key resources, which IAM policies and other Scaleway APIs take as a resource reference; the module does not expose it.

## What Changes

- **BREAKING** `versions.tf`: `required_version` goes from `>= 1.10.7` to `>= 1.11.0` (one constraint, no `.tofu` file, no `language {}` block). Consumers need OpenTofu or Terraform >= 1.11.0. `examples/*/versions.tf` take the same constraint (they say `>= 1.10`).
- **BREAKING** `versions.tf` and `examples/*/versions.tf`: scaleway provider `~> 2.89` becomes `~> 2.93`, the first release with `srn` on these resources. Lock files pinning 2.92 or older need `tofu init -upgrade`.
- New `srn` attribute in the existing map outputs `instances`, `instances_by_group`, `security_groups`, `volumes` and `backup_snapshots`. Purely additive for consumers.
- `.github/workflows/ci.yml` and `release.yml`: `tofu_version` goes from `1.11.0` to the `mise.toml` pin `1.13.10`; no job is added.
- `mise.toml`: `opentofu = '1.13.10'`, new `terraform = '1.17.2'`.
- `.gitlab/release.yml`: `validate:opentofu` uses `ghcr.io/opentofu/opentofu:1.13.10`; new `validate:terraform` job (`hashicorp/terraform:1.17.2`) validates the root and every example; `create:release` needs it.
- `.pre-commit-config.yaml` (hook `rev` unchanged): `terraform_fmt`, `terraform_docs` and `terraform_tflint` get `args: [--hook-config=--tf-path=tofu]` (none had it).
- `openspec/config.yaml`: `terraform` store `ref` v1.2.6 becomes v2.1.0; the context line "required_version >= 1.10.7 ... ~> 2.89" and the Commands line are updated.
- Docs outside the terraform-docs markers: README (Terraform badge, a provider and core requirement note, an upgrade note), `AGENTS.md` (OpenTofu and Terraform >= 1.11.0; `terraform init -backend=false && terraform validate` in the Commands line).
- `tests/main.tftest.hcl`, `examples/complete/`: assert and surface `srn`.

Release level (`terraform-versioning`): **major, next v4.0.0**. The core floor rises (`terraform-providers` scenario "Core floor below the organisation floor") and so does the provider floor (scenario "Raised floor"). Upgrade note: "consumers need OpenTofu or Terraform >= 1.11.0 and the scaleway provider >= 2.93".

Inputs: none change type, default or meaning. Outputs: `instances.*`, `instances_by_group.*.*`, `security_groups.*`, `volumes.*` and `backup_snapshots.*` each gain an `srn` string attribute; no existing attribute changes. State: nothing new is written beyond the `srn` attribute the provider already stores on each resource; none is secret-bearing; no resource is replaced and a second plan is empty. No new top-level output: `placement_group_id` and `ssh_key_id` stay as they are (see design).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `module-contract`: the core floor becomes `>= 1.11.0` for both tools, the provider constraint `~> 2.93`, and `instances` / `instances_by_group` carry `srn`.
- `security-groups`: `security_groups` entries become `{ id, name, srn }`.
- `storage-volumes`: `volumes` entries become `{ id, name, type, srn }`.
- `instances`: `backup_snapshots` entries carry `srn`.

## Impact

- Files: `versions.tf`, `outputs.tf`, `examples/*/versions.tf`, `examples/complete/`, `tests/main.tftest.hcl`, `mise.toml`, `.gitlab/release.yml`, `.pre-commit-config.yaml`, `.github/workflows/*.yml`, `openspec/config.yaml`, `README.md`, `AGENTS.md`.
- `.github/workflows/ci.yml` and `release.yml`: OpenTofu pin only.
- Consumers: must run OpenTofu or Terraform >= 1.11.0 and provider >= 2.93; no state migration.
- Standards applied: `terraform-providers`, `terraform-module-structure`, `terraform-repo-gitlab-ci`, `terraform-repo-mise`, `terraform-repo-precommit`, `terraform-versioning`, `terraform-outputs`.
