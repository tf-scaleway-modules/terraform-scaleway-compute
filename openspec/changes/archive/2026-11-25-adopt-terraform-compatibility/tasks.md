## 1. Branch and standards

- [x] 1.1 Work on `feature/adopt-terraform-compatibility` (cut from `develop`); set the `terraform` store ref to `v2.1.0` in `openspec/config.yaml` (other refs unchanged) and update its context (`required_version >= 1.11.0`, provider `~> 2.93`, Commands line); run `mise run spec-setup` if the store is not at v2.1.0
- [x] 1.2 Fetch `terraform-outputs`, `terraform-code-style` and the BRIEF specs before editing HCL

## 2. Versions and toolchain

- [x] 2.1 `versions.tf` and `examples/minimal|complete/versions.tf`: `required_version = ">= 1.11.0"`, scaleway `~> 2.93`
- [x] 2.2 `mise.toml`: `opentofu = '1.13.10'`, add `terraform = '1.17.2'`; run `mise install`
- [x] 2.3 `.gitlab/release.yml`: OpenTofu image `1.13.10`; add `validate:terraform` after `validate:opentofu` and in `create:release` `needs:`
- [x] 2.5 `.github/workflows/ci.yml` and `release.yml`: `tofu_version: "1.13.10"`, no new job
- [x] 2.4 `.pre-commit-config.yaml`: `args: [--hook-config=--tf-path=tofu]` on `terraform_fmt`, `terraform_docs`, `terraform_tflint`

## 3. srn outputs

- [x] 3.1 `outputs.tf`: add `srn` to `instances`, `instances_by_group`, `security_groups`, `volumes`, `backup_snapshots` (both branches where merged) and update each description
- [x] 3.2 `tests/main.tftest.hcl`: set `srn` in the `mock_resource` defaults and assert `srn` in the instances, instances_by_group, volumes, security group and backup snapshot runs (local and block); check the other test files still pass
- [x] 3.3 `examples/complete/`: surface `srn` (re-exported outputs already pass the maps through; add a note or output only if needed)

## 4. Docs

- [x] 4.1 `README.md` outside the terraform-docs markers: Terraform badge and provider badge, OpenTofu and Terraform >= 1.11.0 and provider >= 2.93 prose, `srn` mention, upgrade note
- [x] 4.2 `AGENTS.md`: name OpenTofu >= 1.11.0 and Terraform >= 1.11.0; add `terraform init -backend=false && terraform validate` to the Commands line
- [x] 4.3 Grep for `1.10.0`, `1.10.7`, `1.11.6`, `v1.2.6`, `2.89`, `2.86` and fix stale prose (never edit `CHANGELOG.md` or the terraform-docs block)

## 5. Verification

- [x] 5.1 `mise exec -- tofu fmt -recursive -check`
- [x] 5.2 `tofu init -backend=false -upgrade && tofu validate` in the root and in each `examples/*`
- [x] 5.3 `tflint --init && tflint --recursive`
- [x] 5.4 `tofu test`
- [x] 5.5 Terraform compatibility in a scratch copy (rsync excluding `.terraform`, `.terraform.lock.hcl`, `.git`, `mise*.toml`; `T=$(mise which terraform)` run from the repo): `$T init -backend=false && $T validate` in the root and each example
- [x] 5.6 `mise exec -- openspec validate --all --strict`
- [x] 5.7 `pre-commit run -a` after moving every `.terraform.lock.hcl` outside the repo; restore them afterwards

## 6. Commit

- [x] 6.1 One signed commit (`git commit -S`), imperative subject that reads as a CHANGELOG line without `feat:` (for example "Require OpenTofu or Terraform 1.11.0, validate with both and expose srn in the outputs"); body: `BREAKING:` consumers need OpenTofu or Terraform >= 1.11.0 and the scaleway provider >= 2.93
