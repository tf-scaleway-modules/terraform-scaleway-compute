## ADDED Requirements

### Requirement: Public IP create before destroy
The module SHALL configure `create_before_destroy = true` lifecycle rule on `scaleway_instance_ip` resources to minimize IP address change downtime during replacements.

#### Scenario: IP replacement creates new before destroying old
- **WHEN** a public IP resource requires replacement
- **THEN** Terraform creates the new IP before destroying the old one

### Requirement: Security group create before destroy
The module SHALL configure `create_before_destroy = true` lifecycle rule on `scaleway_instance_security_group` resources to maintain security coverage during replacements.

#### Scenario: Security group replacement maintains coverage
- **WHEN** a security group resource requires replacement
- **THEN** Terraform creates the new security group before destroying the old one

### Requirement: Documented prevent destroy pattern
The module README SHALL document how users can protect stateful resources from accidental deletion by implementing `prevent_destroy` in their root module.

#### Scenario: Documentation includes prevent destroy example
- **WHEN** user reads the module documentation
- **THEN** they find a code example showing how to use `lifecycle { prevent_destroy = true }` on module resources

### Requirement: Ignore tags changes option
The module SHALL provide a variable to ignore external tag changes on resources, preventing drift from external tagging systems.

#### Scenario: External tags do not cause drift
- **WHEN** `ignore_tags_changes = true` and external system adds tags to instances
- **THEN** terraform plan shows no changes for tag modifications
