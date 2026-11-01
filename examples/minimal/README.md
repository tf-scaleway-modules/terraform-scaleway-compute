# Minimal Example

The smallest viable invocation of `scaleway-compute`: a single `DEV1-S` instance behind the shared security group with SSH allowed from one range.

## What this demonstrates

- A single instance group (`web`) with `count = 1`
- The default shared security group, closed by default
- A single inbound rule allowing SSH from `203.0.113.0/24` (replace it with your own range)

## Usage

Configure the Scaleway provider credentials (the project and zone default to the provider's), then:

```bash
tofu init
tofu plan
tofu apply
```

## Cleanup

```bash
tofu destroy
```
