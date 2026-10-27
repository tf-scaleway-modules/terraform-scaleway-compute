# Design

## Context

- Agent OS here was standards only (`agent-os/standards/`, five commands, Roo skills). No product or shaped-spec content existed.
- `openspec/specs/` held four capability specs in delta format that failed strict validation; `changes/archive/2026-01-30-production-ready-module/` is left untouched.
- The sibling `keycloak`, `vault` and `gitlab-management` modules already use the same stores, `AGENTS.md` shape, setup script and CI job.

## Goals / Non-Goals

**Goals:** one planning system with standards consumed by pinned reference; a valid baseline contract verified against the HCL; zero diff in `*.tf`.

**Non-Goals:** applying the store standards to the code or docs (SECURITY.md, `checks.tf`, write-only SSH key, `tests/main.tftest.hcl` naming, integration fixture); fixing the inconsistencies listed in the migration report.

## Decisions

### 1. Stores pinned through the profile
`openspec/config.yaml` references `quality`, `repository` and `terraform` at released tags (the terraform-module profile). `AGENTS.md` only routes to them; no standard is copied.

### 2. Skills for Claude Code and OpenCode
`openspec-*` skills live in `.claude/skills/` and `.opencode/skills/` (kept identical); the Roo copies are removed with Agent OS.

### 3. CI job `validate:specs`
`.gitlab/specs.yml` runs `openspec validate --all --strict` with `OPENSPEC_VERSION` from `.gitlab/global.yml`; no store is needed in CI.

### 4. Existing specs fixed in place, then extended by deltas
The four main specs are rewritten first so the change validates; the change then ADDs requirements to `input-validation` instead of redefining them. Rules that were wrong are dropped, not reworded into intended behaviour: `ignore_tags_changes`, security group timeouts and the block volume `update` timeout have no code behind them.

### 5. Capability split
`module-contract` carries inputs, defaults and outputs overview. One capability per resource family: `instances`, `security-groups`, `networking` (IPs and private networks), `storage-volumes`, `placement-groups`, `ssh-keys`. The four historical capabilities keep their cross-cutting scope (all `validation` blocks, all preconditions, replacement ordering, timeouts), so each rule is stated once.

### 6. Baseline is today's behaviour, warts included
Group-level rules are not validated like global ones, `ip_address` of a private network is accepted but not sent, and `ssh_public_key` is sensitive but not ephemeral. The baseline does not spec these as guarantees.

### 7. CHANGELOG stays generated
`CHANGELOG.md` is produced by git-cliff from commit subjects (`mise run changelog`); commit subjects read as CHANGELOG lines and the file is regenerated at release.
