# Changelog

All notable changes to this project will be documented in this file.


## [4.0.1] - 2026-11-26
- Rewrite input and output descriptions as single-line prose so they render on the Terraform Registry
## [4.0.0] - 2026-11-25
- Require OpenTofu or Terraform 1.11.0, validate with both and expose srn in the outputs

Raise required_version to >= 1.11.0 and the scaleway provider to ~> 2.93, add
srn to the instances, instances_by_group, security_groups, volumes and
backup_snapshots outputs, pin OpenTofu 1.13.10 and Terraform 1.17.2 in mise,
add a Terraform validation job to the GitLab release pipeline, bump the GitHub
workflows to OpenTofu 1.13.10 and run the pre-commit Terraform hooks with tofu.

BREAKING: required_version moves from >= 1.10.7 to >= 1.11.0 and the scaleway
provider from ~> 2.89 to ~> 2.93. Consumers need OpenTofu or Terraform >= 1.11.0
and scaleway provider >= 2.93 (run tofu init -upgrade).
## [3.0.1] - 2026-11-25
- Fix validation with provider 2.92.0+ by dropping the timeouts block from SBS block volumes

Provider 2.92.0 moved scaleway_block_volume to the plugin framework and removed its timeouts block, so any fresh init (~> 2.89 resolves to 2.93) failed tofu validate. The timeouts input now applies to instances only; block volumes keep the provider defaults.
## [3.0.0] - 2026-11-01
- Add private NIC security groups, IPv6 IPs and SBS root backups; replace the project lookup with project_id

BREAKING: v3.0.0 reworks inputs, outputs and defaults; provider ~> 2.89.

- organization_id/project_name are replaced by project_id (null = provider
  default project); zone defaults to the provider zone.
- create_ssh_key and ssh_public_key_file are removed: the key is created
  when ssh_public_key is set.
- The flat security group and placement group inputs become the
  security_group and placement_group objects; placement policy_mode is
  dropped (deprecated by the provider).
- inbound_rules defaults to [] (no SSH rule open to 0.0.0.0/0).
- private_networks is a list of network IDs attached through
  scaleway_instance_private_nic resources, with an opt-in security group
  per NIC (enable_private_nic_security_group); import the NICs or detach
  them on v2.2.0 before upgrading.
- public_ip_type moves to each group and drops nat; enable_ipv6 adds a
  routed IPv6 IP; security group rules accept IPv6 ranges.
- b_ssd root volumes are rejected; SBS roots are backed up through
  scaleway_block_snapshot (new backup_snapshots output).
- Outputs project_id, group_security_group_ids, block_volumes, public_ips
  and private_ips are removed; instances expose address lists.

See "Upgrading from v2 to v3" in the README.
## [2.2.0] - 2026-10-31
- Add SBS root volume with IOPS and deletion protection to instance groups

Groups accept root_volume_type "sbs_volume" with an optional
root_volume_sbs_iops (5000 or 15000) and enable_protection to reject
server deletion through the API. SBS roots cannot use backup snapshots.
Provider floor stays ~> 2.86; minor release, no input or output removed.
## [2.1.2] - 2026-10-28
- Validate group-level rules and CIDRs, warn on ignored inputs, fix README

- Group-level inbound_rules/outbound_rules and default policies get the same validation as the global variables.
- CIDR validation rejects out-of-range values such as 999.0.0.0/99.
- Check blocks warn about accepted but ignored inputs: instances[*].create_security_group, private_networks[*].ip_address, and security_group_id while create_security_group = true.
- README: remove the nonexistent ignore_tags_changes, fix the timeouts scope and document how the project SSH key reaches instances.
Configurations that already failed at apply now fail at plan; no other upgrade action.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
## [2.1.1] - 2026-10-28
- Install mise 2026.10.17 in CI to avoid the GitHub API rate limit

The pre-commit job installed an old mise that resolves every tool through api.github.com without a token, and failed with 403 rate-limit errors on the shared office runner whenever its cache was cold (new refs such as merge requests and tags). mise 2026.9.14 and later resolve releases through mise-versions.jdx.dev.
- Run validate:specs in merge request pipelines

A job without rules: only runs in branch and tag pipelines, so the merge request pipeline did not validate openspec/. rules: when: always matches the other validate jobs.
- Move from Agent OS to OpenSpec and publish the baseline specs

Planning moves from Agent OS to OpenSpec: agent-os/standards/ and the
Agent OS commands are removed, the engineering standards now come from the
quality, repository and terraform OpenSpec stores. openspec/config.yaml follows the terraform-module profile
(stores pinned at quality v1.2.6, repository v4.1.0, terraform v1.2.6) and
AGENTS.md, imported by CLAUDE.md, routes to them. openspec/specs/ holds the
baseline specification of the module as released, produced by the archived
adopt-openspec change. The openspec-* skills are installed for Claude Code
and OpenCode, openspec 1.14.3 and node are pinned in mise.toml with the
spec-validate and spec-setup tasks, and the validate:specs CI job runs
openspec validate --all --strict. The module contract is unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- ci: let osv-scanner pass on a repo without lockfiles

- pre-commit: osv-scanner 2.x exits 128 with "No package sources found"
  on this Terraform-only repo, which failed the job and skipped
  create:release; pass --allow-no-lockfiles.
- Cache keys follow mise.toml / .pre-commit-config.yaml instead of the
  ref, so branches and tags share one cache instead of each leaving its
  own copy on the runner disk.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
## [2.1.0] - 2026-10-14
- chore(deps): upgrade scaleway provider to ~> 2.86

- Bump the scaleway provider constraint to ~> 2.86 (module and examples).
- placement_group_policy_mode now defaults to null: policy_mode is
  deprecated by the provider (removed with Instance API v1); the API
  default (optional) still applies.
- Tests: mock zoned IDs (zone/uuid); since 2.76 the provider validates
  security_group_id on scaleway_instance_security_group_rules.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- Upgrade OpenSpec to 1.14.0 with Claude Code and OpenCode skills

Pin @fission-ai/openspec 1.14.0 in mise.toml and regenerate the
OpenSpec instruction files for Claude Code and OpenCode (skills
delivery). Legacy opsx-* command files are removed in favor of skills.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
## [2.0.0] - 2026-04-27
- chore: Update development tools and CI/CD dependencies
- feat: implement Agent OS framework and project standards
- typo
- feat: add production-ready module enhancements

- Add comprehensive input validation for zone, instance types, volume
  types, security policies, protocols, and CIDR ranges
- Add lifecycle management with create_before_destroy for IPs and
  security groups
- Add runtime preconditions for SSH key and external volume validation
- Add configurable timeouts for instances and block volumes
- Update documentation with Resource Timeouts and Lifecycle Protection
  sections
- Add OpenSpec workflow configuration and archived change artifacts
## [1.0.0] - 2025-12-19
- merge from develop
- mise update - git-cliff installation
- Configures terraform_fmt hook to use tofu
- Introduces  variable for resource naming
- Introduces  variable for resource naming
- Implements per-group security group configuration
- Adds external volume attachment support
- Enables SBS block volume support
- Enables complete example with all features
- Adds complete example with all features
- Adds complete example with all features
- Adds complete example with all features.
- Refactors module to support instance groups
- major refactoring
- first commit
- main merge
- Initial commit
