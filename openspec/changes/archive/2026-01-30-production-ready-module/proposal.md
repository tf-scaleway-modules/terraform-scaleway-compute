## Why

This Terraform module for Scaleway compute infrastructure lacks production-hardening features that are essential for enterprise use. While the core functionality is solid and CI/CD tooling is already in place, the module needs enhanced validation, lifecycle management, and runtime checks to be considered truly production-ready.

## What Changes

- **Input Validation**: Add comprehensive variable validations for zones, instance types, image names, IP ranges, and other critical inputs to fail fast with clear error messages
- **Lifecycle Management**: Add `prevent_destroy` lifecycle rules for critical resources (instances with backups, volumes with data) and configurable `create_before_destroy` behavior
- **Preconditions/Postconditions**: Add runtime checks using Terraform 1.2+ preconditions to validate assumptions (e.g., SSH key exists when required, private network IDs are valid format)
- **Resource Timeouts**: Add configurable timeouts for long-running operations (instance creation, volume attachment)

## Capabilities

### New Capabilities

- `input-validation`: Comprehensive variable validations with clear error messages for all user inputs (zones, instance types, CIDR ranges, naming conventions)
- `lifecycle-management`: Configurable lifecycle rules including prevent_destroy for stateful resources and create_before_destroy options
- `runtime-checks`: Preconditions and postconditions for runtime validation of resource relationships and external dependencies
- `resource-timeouts`: Configurable timeouts for instance, volume, and security group operations

### Modified Capabilities

<!-- No existing specs to modify - this is a greenfield OpenSpec setup -->

## Impact

- **variables.tf**: Additional validation blocks for existing variables
- **main.tf**: Lifecycle blocks, timeouts, and preconditions added to resources
- **versions.tf**: Minimum Terraform version may increase to 1.2+ for preconditions
- **Examples**: May need updates to pass stricter validations
- **Documentation**: README updates for new validation requirements
