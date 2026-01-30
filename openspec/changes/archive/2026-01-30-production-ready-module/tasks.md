## 1. Input Validation - Core Variables

- [x] 1.1 Add `zone` validation with regex for Scaleway zone format (e.g., `fr-par-1`, `nl-ams-1`)
- [x] 1.2 Add `inbound_default_policy` validation for enum: `accept`, `drop`
- [x] 1.3 Add `outbound_default_policy` validation for enum: `accept`, `drop`
- [x] 1.4 Add `placement_group_policy_type` validation for enum: `low_latency`, `max_availability`
- [x] 1.5 Add `placement_group_policy_mode` validation for enum: `optional`, `enforced`
- [x] 1.6 Add `public_ip_type` validation for enum: `routed_ipv4`, `routed_ipv6`, `nat`

## 2. Input Validation - Instance Configuration

- [x] 2.1 Add `instances[*].instance_type` validation with regex for Scaleway instance type format
- [x] 2.2 Add `instances[*].root_volume_type` validation for enum: `l_ssd`, `b_ssd`
- [x] 2.3 Add `instances[*].state` validation for enum: `started`, `stopped`, `standby`
- [x] 2.4 Add `instances[*].additional_volumes[*].type` validation for enum: `l_ssd`, `sbs_5k`, `sbs_15k`

## 3. Input Validation - Security Rules

- [x] 3.1 Add `inbound_rules[*].protocol` validation for enum: `TCP`, `UDP`, `ICMP`, `ANY`
- [x] 3.2 Add `outbound_rules[*].protocol` validation for enum: `TCP`, `UDP`, `ICMP`, `ANY`
- [x] 3.3 Add `inbound_rules[*].ip_range` validation with CIDR regex pattern
- [x] 3.4 Add `outbound_rules[*].ip_range` validation with CIDR regex pattern
- [x] 3.5 Add validation that `port` and `port_range` are mutually exclusive in security rules

## 4. Lifecycle Management

- [x] 4.1 Add `create_before_destroy = true` lifecycle block to `scaleway_instance_ip` resource
- [x] 4.2 Add `create_before_destroy = true` lifecycle block to `scaleway_instance_security_group.shared` resource
- [x] 4.3 Add `create_before_destroy = true` lifecycle block to `scaleway_instance_security_group.group` resource
- [x] 4.4 Add `ignore_tags_changes` variable (bool, default false)
- [x] 4.5 Add conditional `ignore_changes = [tags]` lifecycle rule to instance resources when enabled

## 5. Runtime Checks - Preconditions

- [x] 5.1 Add precondition to `scaleway_iam_ssh_key.this` validating SSH key content is provided when creation enabled
- [x] 5.2 Add precondition to `scaleway_instance_server.this` validating external volumes only used with count=1
- [x] 5.3 Add validation that `security_group_id` and custom `inbound_rules`/`outbound_rules` are mutually exclusive

## 6. Resource Timeouts

- [x] 6.1 Add `timeouts` variable with create/update/delete optional string fields (default 10m each)
- [x] 6.2 Add `timeouts` block to `scaleway_instance_server.this` resource
- [x] 6.3 Add `timeouts` block to `scaleway_block_volume.this` resource
- [x] 6.4 ~~Add `timeouts` block to `scaleway_instance_security_group.shared` resource~~ (not supported by provider)
- [x] 6.5 ~~Add `timeouts` block to `scaleway_instance_security_group.group` resource~~ (not supported by provider)

## 7. Documentation

- [x] 7.1 Update README with new `timeouts` variable documentation
- [x] 7.2 Update README with new `ignore_tags_changes` variable documentation
- [x] 7.3 Add "Lifecycle Protection" section to README with `prevent_destroy` pattern example
- [x] 7.4 Run `terraform-docs` to regenerate variable/output tables

## 8. Verification

- [x] 8.1 Run `tofu validate` to verify all changes are syntactically correct
- [x] 8.2 Run `tofu fmt -recursive` to ensure consistent formatting
- [x] 8.3 Verify minimal example passes validation with new rules
- [x] 8.4 Verify complete example passes validation with new rules (fixed project_name placeholder)
- [x] 8.5 Run `tflint` to check for additional issues (ignore_tags_changes warning documented)
