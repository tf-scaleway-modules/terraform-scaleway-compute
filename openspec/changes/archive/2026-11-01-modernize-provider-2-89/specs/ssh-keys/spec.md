## REMOVED Requirements

### Requirement: Optional SSH key
**Reason**: `create_ssh_key` and `ssh_public_key_file` are removed; creation follows `ssh_public_key`.
**Migration**: `ssh_public_key = file("~/.ssh/id_ed25519.pub")`; drop `create_ssh_key`.

## ADDED Requirements

### Requirement: SSH key from public key content
When `ssh_public_key` is set, the module SHALL create one `scaleway_iam_ssh_key` named `<name>-ssh-key` in `project_id` with that public key; when it is null no key SHALL be created. There is no file input: callers pass `file("...")`.

#### Scenario: Key from content
- **WHEN** `ssh_public_key = "ssh-ed25519 AAAA... user@host"`
- **THEN** one SSH key is planned with that content

#### Scenario: Not created by default
- **WHEN** `ssh_public_key` is null
- **THEN** no SSH key is planned

## MODIFIED Requirements

### Requirement: SSH key output
The module SHALL output `ssh_key_id` as the created key's ID, or null when no key is created.

#### Scenario: No key
- **WHEN** `ssh_public_key` is null
- **THEN** `ssh_key_id` is null

### Requirement: SSH key created before servers
When `ssh_public_key` is set, the module SHALL create the SSH key before any server. The key is scoped to the Project and Scaleway copies it to every Instance of that Project, not only to those of this module, when the Instance boots.

#### Scenario: Key and servers in one apply
- **WHEN** `ssh_public_key` is set and an instance group has `count = 1`
- **THEN** the server depends on the SSH key, so the key exists when the server first boots
