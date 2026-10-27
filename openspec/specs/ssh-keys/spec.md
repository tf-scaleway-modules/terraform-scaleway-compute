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
The `ssh_public_key` input SHALL be marked `sensitive`.

#### Scenario: Plan output
- **WHEN** `ssh_public_key` is set
- **THEN** its value is redacted in plan output

### Requirement: SSH key output
The module SHALL output `ssh_key_id` as the created key's ID, or null when no key is created.

#### Scenario: No key
- **WHEN** `create_ssh_key = false`
- **THEN** `ssh_key_id` is null
