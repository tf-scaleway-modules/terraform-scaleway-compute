# Tasks

## 1. Tooling

- [x] 1.1 Pin `node` and `openspec` in `mise.toml` and add the `spec-validate` and `spec-setup` tasks
- [x] 1.2 Add `scripts/openspec-setup.sh` and `.gitlab/specs.yml`, include it in `.gitlab-ci.yml`, set `OPENSPEC_VERSION` in `.gitlab/global.yml`
- [x] 1.3 Install the `openspec-*` skills in `.claude/skills/` and `.opencode/skills/`

## 2. Configuration

- [x] 2.1 Fill `openspec/config.yaml` context, rules and operations for this module (git-cliff CHANGELOG, `tofu test`, no scan/test tasks)
- [x] 2.2 Fill `AGENTS.md` and add `CLAUDE.md`

## 3. Remove Agent OS

- [x] 3.1 Delete `agent-os/`, `.claude/commands/agent-os/` and `.roo/skills/`
- [x] 3.2 Add the OpenSpec workflow to the README "Contributing" section, outside the terraform-docs markers

## 4. Specs

- [x] 4.1 Rewrite the four existing main specs into main-spec format and check each requirement against the HCL
- [x] 4.2 Write the delta specs for `module-contract`, `instances`, `security-groups`, `networking`, `storage-volumes`, `placement-groups`, `ssh-keys` and the additions to `input-validation`
- [x] 4.3 Verify no `*.tf`, `examples/` or `tests/` file changed
- [x] 4.4 `openspec validate --all --strict` passes (same command as the `validate:specs` CI job)
- [x] 4.5 Archive the change and replace the `TBD` purposes
- [x] 4.6 `pre-commit run` passes on the changed files
