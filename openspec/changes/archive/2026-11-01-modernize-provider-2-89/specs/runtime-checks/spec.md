## REMOVED Requirements

### Requirement: SSH key content precondition
**Reason**: `create_ssh_key` and `ssh_public_key_file` are removed; the key is created exactly when `ssh_public_key` is set, so there is no inconsistent state to guard.
**Migration**: Set `ssh_public_key`; drop `create_ssh_key`.

### Requirement: Ignored group security group flag warning
**Reason**: The group attribute `create_security_group` is removed, so it can no longer be set and ignored.
**Migration**: Delete `create_security_group` from the group; use `security_group = { id = ... }` to reuse a group.

### Requirement: Ignored private network IP warning
**Reason**: `ip_address` is removed from `private_networks`, which is now a list of network IDs.
**Migration**: Pass network IDs only.

### Requirement: Ignored external security group warning
**Reason**: `create_security_group` and `security_group_id` are folded into `security_group`, where an ID means "use this group" and nothing is ignored.
**Migration**: `security_group = { id = ... }`.
