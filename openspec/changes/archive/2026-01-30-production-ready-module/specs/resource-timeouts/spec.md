## ADDED Requirements

### Requirement: Configurable instance timeouts
The module SHALL provide a `timeouts` variable to configure create, update, and delete timeouts for instance resources.

#### Scenario: Default timeouts applied
- **WHEN** user does not specify `timeouts` variable
- **THEN** instance operations use default timeout of 10 minutes for create, update, and delete

#### Scenario: Custom timeouts applied
- **WHEN** user specifies `timeouts = { create = "20m", delete = "15m" }`
- **THEN** instance create operations timeout after 20 minutes and delete operations timeout after 15 minutes

### Requirement: Configurable volume timeouts
The module SHALL apply the `timeouts` configuration to block volume resources.

#### Scenario: Volume creation respects timeout
- **WHEN** user specifies `timeouts = { create = "15m" }`
- **THEN** block volume creation operations timeout after 15 minutes

### Requirement: Configurable security group timeouts
The module SHALL apply the `timeouts` configuration to security group resources.

#### Scenario: Security group creation respects timeout
- **WHEN** user specifies `timeouts = { create = "5m" }`
- **THEN** security group creation operations timeout after 5 minutes

### Requirement: Timeout variable structure
The module SHALL accept a `timeouts` variable with optional `create`, `update`, and `delete` string fields in duration format (e.g., "10m", "1h").

#### Scenario: Partial timeout configuration
- **WHEN** user specifies `timeouts = { create = "20m" }` without update or delete
- **THEN** create uses 20 minutes and update/delete use defaults

#### Scenario: Empty timeout uses defaults
- **WHEN** user specifies `timeouts = {}`
- **THEN** all operations use default timeout of 10 minutes
