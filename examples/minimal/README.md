# Minimal Example

The smallest viable invocation of `scaleway-compute`: a single `DEV1-S` instance behind the shared security group with port 22 open.

## What this demonstrates

- A single instance group (`web`) with `count = 1`
- The default shared security group (`create_security_group` defaults to `true`)
- A single inbound rule allowing SSH from anywhere

## Usage

Replace `organization_id` with your Scaleway organization UUID, then:

```bash
tofu init
tofu plan
tofu apply
```

## Cleanup

```bash
tofu destroy
```
