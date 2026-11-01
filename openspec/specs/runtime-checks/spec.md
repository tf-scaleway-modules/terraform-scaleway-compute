# runtime-checks Specification

## Purpose
Resource `precondition` blocks that reject inconsistent combinations of inputs at plan time.

## Requirements

### Requirement: External volume single instance precondition
The module SHALL fail the plan when an instance group with a non-empty `external_volume_ids` has `count` greater than 1.

#### Scenario: External volume with single instance succeeds
- **WHEN** a group has `count = 1` and `external_volume_ids = ["vol-123"]`
- **THEN** the plan succeeds

#### Scenario: External volume with multiple instances fails
- **WHEN** a group has `count = 2` and `external_volume_ids = ["vol-123"]`
- **THEN** the plan fails with "External volumes can only be used when instance group count is 1."
