## MODIFIED Requirements

### Requirement: SSH key public content is sensitive
The `ssh_public_key` input SHALL be marked `sensitive` so its value is redacted in plan output. It SHALL NOT be `ephemeral`, because `scaleway_iam_ssh_key` has no write-only argument; the key is a public key and the value is stored in state. Its description SHALL state this.

#### Scenario: Plan output
- **WHEN** `ssh_public_key` is set
- **THEN** its value is redacted in plan output

## ADDED Requirements

### Requirement: SSH key created before servers
When `create_ssh_key = true`, the module SHALL create the SSH key before any server. The key is scoped to the Project and Scaleway copies it to every Instance of that Project, not only to those of this module, when the Instance boots.

#### Scenario: Key and servers in one apply
- **WHEN** `create_ssh_key = true` and an instance group has `count = 1`
- **THEN** the server depends on the SSH key, so the key exists when the server first boots
