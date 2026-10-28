## 1. Validations

- [x] 1.1 Replace the CIDR regex with `can(cidrhost(...))` plus an IPv4-only test on `inbound_rules` and `outbound_rules`
- [x] 1.2 Add group-level validations on `instances` (protocol, CIDR, port/port_range, default policies)
- [x] 1.3 Tests: rejected-input runs in `tests/validations.tftest.hcl` (out-of-range CIDR, each group-level rule)

## 2. Checks and descriptions

- [x] 2.1 Add `checks.tf` with `group_create_security_group_ignored`, `private_network_ip_address_ignored`, `security_group_id_ignored`
- [x] 2.2 Fix descriptions of `private_networks`, `security_group_id`, `ssh_public_key` and the `instances` type comments
- [x] 2.3 Tests: `tests/main.tftest.hcl` with one run per check (`expect_failures = [check.*]`) and a happy path with no warning

## 3. Documentation and examples

- [x] 3.1 README: remove `ignore_tags_changes`, correct the timeouts scope, document the SSH key behaviour
- [x] 3.2 Confirm `examples/complete` and `examples/minimal` use no ignored input
- [x] 3.3 Update the `openspec/config.yaml` context line that says there is no `checks.tf`

## 4. Verification

- [x] 4.1 `tofu fmt -recursive`, `tofu validate`, `tflint --recursive`, `tofu test`, `pre-commit run -a`
- [x] 4.2 `openspec validate --all --strict`, archive, validate again
