## Context

This is a Scaleway compute Terraform module that provisions instances, security groups, placement groups, volumes, and SSH keys. The module is functionally complete with good examples and documentation, but lacks defensive coding patterns that prevent misconfigurations at plan time rather than apply time.

**Current state:**
- Variables have minimal validation (only `project_name` regex and `instances` count range)
- No lifecycle blocks on any resources
- No timeouts configured (uses provider defaults)
- No preconditions/postconditions for runtime checks
- Terraform version requirement: `>= 1.10.7` (supports all planned features)

**Constraints:**
- Must maintain backward compatibility with existing usage
- New variables for lifecycle/timeout control must have sensible defaults
- Validation errors must be clear and actionable

## Goals / Non-Goals

**Goals:**
- Fail fast with clear error messages for invalid inputs at `terraform plan`
- Protect stateful resources from accidental deletion
- Provide configurable timeouts for slow cloud operations
- Validate runtime assumptions before resource creation

**Non-Goals:**
- Adding new resource types or features
- Changing existing variable defaults (unless for safety)
- Breaking changes to the module interface
- Adding integration tests (separate effort)

## Decisions

### 1. Input Validation Strategy

**Decision:** Add validation blocks to existing variables in `variables.tf`

**Validations to add:**

| Variable | Validation | Rationale |
|----------|------------|-----------|
| `zone` | Regex for valid Scaleway zones | Prevent typos like `fr-par1` vs `fr-par-1` |
| `instances[*].instance_type` | Regex for valid instance type format | Catch invalid types early |
| `instances[*].root_volume_type` | Enum: `l_ssd`, `b_ssd` | Only valid volume types |
| `instances[*].state` | Enum: `started`, `stopped`, `standby` | Only valid states |
| `instances[*].additional_volumes[*].type` | Enum: `l_ssd`, `sbs_5k`, `sbs_15k` | Valid volume types |
| `inbound_rules[*].protocol` | Enum: `TCP`, `UDP`, `ICMP`, `ANY` | Valid protocols |
| `inbound_rules[*].ip_range` | CIDR regex validation | Catch malformed CIDRs |
| `inbound_default_policy` | Enum: `accept`, `drop` | Only valid policies |
| `outbound_default_policy` | Enum: `accept`, `drop` | Only valid policies |
| `placement_group_policy_type` | Enum: `low_latency`, `max_availability` | Valid policies |
| `placement_group_policy_mode` | Enum: `optional`, `enforced` | Valid modes |
| `public_ip_type` | Enum: `routed_ipv4`, `routed_ipv6`, `nat` | Valid IP types |

**Alternatives considered:**
- Using `tflint` rules only: Rejected because validations in code are self-documenting and always enforced
- Custom validation module: Overkill for this scope

### 2. Lifecycle Management Approach

**Decision:** Add new variables to control lifecycle behavior, defaulting to safe values

```hcl
variable "prevent_destroy_instances" {
  description = "Prevent destruction of instances with backup enabled"
  type        = bool
  default     = false  # Opt-in to avoid breaking existing workflows
}

variable "prevent_destroy_volumes" {
  description = "Prevent destruction of SBS block volumes"
  type        = bool
  default     = false
}
```

**Implementation:**
- Use `dynamic` lifecycle blocks (not supported) → Use `count`-based resource duplication or `lifecycle` with static values
- Since Terraform doesn't support dynamic lifecycle blocks, we'll use static `prevent_destroy = false` as default and document that users should override in their root module if needed

**Revised decision:** Add lifecycle blocks with `create_before_destroy = true` for IP addresses and security groups to minimize downtime. Document `prevent_destroy` pattern for users to implement in their root module.

**Alternatives considered:**
- Terraform moved/import blocks: Not applicable for lifecycle protection
- Wrapper module: Adds complexity for users

### 3. Resource Timeouts

**Decision:** Add configurable timeout variables with sensible defaults

```hcl
variable "timeouts" {
  description = "Resource operation timeouts"
  type = object({
    create = optional(string, "10m")
    update = optional(string, "10m")
    delete = optional(string, "10m")
  })
  default = {}
}
```

Apply to:
- `scaleway_instance_server` - instance creation can be slow
- `scaleway_block_volume` - volume operations
- `scaleway_instance_security_group` - usually fast, but include for consistency

**Alternatives considered:**
- Per-resource-type timeouts: Too granular, adds variable bloat
- No timeouts: Provider defaults may be too short for large deployments

### 4. Preconditions/Postconditions

**Decision:** Add preconditions for critical assumptions

| Resource | Precondition | Error Message |
|----------|--------------|---------------|
| `scaleway_iam_ssh_key.this` | `var.create_ssh_key == false \|\| local.ssh_public_key_content != null` | "SSH key creation requires either ssh_public_key or ssh_public_key_file" |
| `scaleway_instance_server.this` | `each.value.external_volume_ids == [] \|\| length(each.value.external_volume_ids) <= 1 \|\| var.instances[each.value.group_name].count <= 1` | "External volumes can only be attached when instance count is 1 (volumes cannot be shared)" |

**Alternatives considered:**
- Only validation blocks: Cannot check cross-variable logic
- Assert in locals: Preconditions provide better error context

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Stricter validations may reject previously-accepted inputs | Review existing examples pass all validations before merge |
| `create_before_destroy` on IPs may cause IP changes | Document behavior; users can set `create_public_ip = false` and manage IPs externally |
| Timeout defaults may be too short for some regions | Make timeouts configurable; document how to increase |
| Preconditions add Terraform 1.2+ requirement | Already require 1.10.7+, so no impact |

## Migration Plan

1. **Add validations** - No migration needed, but verify examples pass
2. **Add lifecycle blocks** - No state changes, transparent to users
3. **Add timeouts variable** - Optional, defaults maintain current behavior
4. **Add preconditions** - May surface existing misconfigurations (feature, not bug)

**Rollback:** Revert commit. No state migration required.
