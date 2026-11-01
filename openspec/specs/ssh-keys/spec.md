# ssh-keys Specification

## Purpose
Optional IAM SSH key created from inline content or a public key file.

## Requirements

### Requirement: SSH key public content is sensitive
The `ssh_public_key` input SHALL be marked `sensitive` so its value is redacted in plan output. It SHALL NOT be `ephemeral`, because `scaleway_iam_ssh_key` has no write-only argument; the key is a public key and the value is stored in state. Its description SHALL state this.

#### Scenario: Plan output
- **WHEN** `ssh_public_key` is set
- **THEN** its value is redacted in plan output

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

### Requirement: SSH key from public key content
When `ssh_public_key` is set, the module SHALL create one `scaleway_iam_ssh_key` named `<name>-ssh-key` in `project_id` with that public key; when it is null no key SHALL be created. There is no file input: callers pass `file("...")`.

#### Scenario: Key from content
- **WHEN** `ssh_public_key = "ssh-ed25519 AAAA... user@host"`
- **THEN** one SSH key is planned with that content

#### Scenario: Not created by default
- **WHEN** `ssh_public_key` is null
- **THEN** no SSH key is planned
