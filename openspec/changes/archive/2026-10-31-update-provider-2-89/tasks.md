## 1. Inputs and validations

- [x] 1.1 `variables.tf`: add `root_volume_sbs_iops = optional(number)` and `enable_protection = optional(bool, false)` to `instances`; add `sbs_volume` to the root volume type validation and message. Verify: `tofu validate` passes.
- [x] 1.2 `variables.tf`: add validations for IOPS (only with `sbs_volume`, value 5000 or 15000) and for `enable_backup_snapshot` with `sbs_volume`, messages exactly as in the specs. Verify: step 1.3 runs fail with the expected variable.
- [x] 1.3 `tests/validations.tftest.hcl`: one run with `expect_failures = [var.instances]` for each new validation (`root_volume_type = "ssd"` message set, IOPS with `l_ssd`, IOPS `7000`, `sbs_volume` + `enable_backup_snapshot`) and one accepted run for `sbs_volume` + `5000`. Verify: `tofu test` passes, mock_provider "scaleway".

## 2. Wiring

- [x] 2.1 `locals.tf` + `main.tf`: carry both attributes in `instances_flat`; set `protected` and `root_volume.sbs_iops` on `scaleway_instance_server.this` (null when unset). Verify: step 2.2 asserts.
- [x] 2.2 `tests/instance_flattening.tftest.hcl`: runs asserting an SBS root with IOPS 15000, an SBS root without IOPS (`sbs_iops` null), `protected = true` with `enable_protection = true`, and `protected = false` by default. Verify: `tofu test` passes.

## 3. Documentation and examples

- [x] 3.1 `examples/complete/main.tf`: set `enable_protection = true` on the `database` group and an SBS root (`root_volume_type = "sbs_volume"`, `root_volume_sbs_iops = 15000`, no backup snapshot) on a group that does not use backups (for example `cache`); keep `examples/minimal` unchanged. Verify: `tofu init -backend=false && tofu validate` in `examples/complete`.
- [x] 3.2 README: terraform-docs block regenerated (task 4.2); add a short usage note on SBS roots (no backup snapshot, `l_ssd` to `sbs_volume` is a replacement, run `tofu init -upgrade` for the 2.88.0 IOPS fix) and on protected servers (set `enable_protection = false` and apply before destroy). No upgrade note for breaking changes is needed: the change is minor. Verify: README renders the three new attributes.
- [x] 3.3 `openspec/config.yaml` context: no edit needed (provider pin unchanged). Verify: `git diff openspec/config.yaml` is empty.

## 4. Verification and commit

- [x] 4.1 Run `tofu fmt -recursive`, `tofu init -backend=false && tofu validate`, `tflint --recursive`, `tofu test`. Verify: all pass; report output as-is.
- [x] 4.2 Move `.terraform.lock.hcl` aside, then run `pre-commit run -a` and move it back. Known pitfall: with a local lock file terraform-docs writes the locked provider version (2.89.0) into the README instead of the `~> 2.86` constraint; do the same before pushing. Verify: README still shows `~> 2.86`.
- [x] 4.3 `openspec validate --all --strict`, archive the change, validate again. Verify: both pass.
- [x] 4.4 Commit with the subject `Add SBS root volume with IOPS and deletion protection to instance groups`, which reads as the CHANGELOG line (git-cliff generates `CHANGELOG.md`; do not edit it). Release as a minor version; the provider floor stays `~> 2.86`, no README upgrade note needed. Verify: `git log -1 --format=%s`.
