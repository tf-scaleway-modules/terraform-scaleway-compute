# ssh-keys Specification

## Purpose
Optional IAM SSH key created from inline content or a public key file.

## Requirements

### Requirement: Optional SSH key
When `create_ssh_key = true`, the module SHALL create one `scaleway_iam_ssh_key` named `<name>-ssh-key` in the resolved project, whose public key is `ssh_public_key` when set, else the content of the file `ssh_public_key_file`; with the default `create_ssh_key = false` no key SHALL be created.

#### Scenario: Key from content
- **WHEN** `create_ssh_key = true` and `ssh_public_key` is set
- **THEN** one SSH key is planned with that content

#### Scenario: Key from file
- **WHEN** `create_ssh_key = true`, `ssh_public_key` is null and `ssh_public_key_file` points to a public key file
- **THEN** one SSH key is planned with the content of the file

#### Scenario: Not created by default
- **WHEN** `create_ssh_key` is left at its default
- **THEN** no SSH key is planned

### Requirement: SSH key public content is sensitive
The `ssh_public_key` input SHALL be marked `sensitive` so its value is redacted in plan output. It SHALL NOT be `ephemeral`, because `scaleway_iam_ssh_key` has no write-only argument; the key is a public key and the value is stored in state. Its description SHALL state this.

#### Scenario: Plan output
- **WHEN** `ssh_public_key` is set
- **THEN** its value is redacted in plan output

### Requirement: SSH key output
The module SHALL output `ssh_key_id` as the created key's ID, or null when no key is created.

#### Scenario: No key
- **WHEN** `create_ssh_key = false`
- **THEN** `ssh_key_id` is null

### Requirement: SSH key created before servers
When `create_ssh_key = true`, the module SHALL create the SSH key before any server. The key is scoped to the Project and Scaleway copies it to every Instance of that Project, not only to those of this module, when the Instance boots.

#### Scenario: Key and servers in one apply
- **WHEN** `create_ssh_key = true` and an instance group has `count = 1`
- **THEN** the server depends on the SSH key, so the key exists when the server first boots
