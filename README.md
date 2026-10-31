# Scaleway Compute Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]
[![Latest Release][release-badge]][release-url]

A production-ready Terraform module for creating and managing **Scaleway** Compute infrastructure.

## Features

- **Multi-Instance Groups**: Define multiple groups (backend, frontend, database) with different configurations
- **Two-Tier Security Groups**: Shared security group for all instances + per-group security groups with merged rules
- **Multiple Private Networks**: Connect instances to multiple VPC private networks simultaneously
- **SBS Block Storage**: Additional SBS volumes per instance with configurable IOPS (5k/15k)
- **External Volume Attachment**: Attach externally created volumes to instances via IDs
- **Placement Groups**: High availability or low latency configurations
- **Cloud-Init**: Full cloud-init and user data support per group
- **Private NICs**: One private NIC per server and network, optionally filtered by a security group
- **SSH Keys**: Optional Project-level IAM SSH key
- **Backup Snapshots**: Optional root volume snapshots per instance group (local and SBS roots)
- **Public IPs**: Reserved public IP per instance, optionally dual stack (IPv4 + IPv6)

## Usage Examples

Comprehensive examples are available in the [`examples/`](examples/) directory:

- **[Minimal](examples/minimal/)** - Simplest configuration for quick start
- **[Complete](examples/complete/)** - Full-featured production setup

### Quick Start

```hcl
module "compute" {
  source = "git::https://gitlab.com/leminnov/terraform/modules/scaleway-compute.git"

  name = "myapp" # Used for resource naming: myapp-web-00, myapp-shared-sg, etc.

  instances = {
    web = {
      count         = 1
      instance_type = "DEV1-S"
    }
  }

  # Closed by default: list every port you need (SSH from your own range here)
  security_group = {
    inbound_rules = [
      { protocol = "TCP", port = 22, ip_range = "203.0.113.0/24" }
    ]
  }
}
```

### Production Setup with Multiple Instance Groups

```hcl
# Create VPC private networks
resource "scaleway_vpc_private_network" "main" {
  name = "main-network"
}

resource "scaleway_vpc_private_network" "data" {
  name = "data-network"
}

module "compute" {
  source = "git::https://gitlab.com/leminnov/terraform/modules/scaleway-compute.git"

  name       = "ecommerce-prod"
  project_id = "11111110-d164-47ec-8d04-111111111111"
  zone       = "fr-par-1"

  tags = ["production"]

  # Default private network for all instances
  private_networks = [scaleway_vpc_private_network.main.id]

  # Multiple instance groups with different configurations
  instances = {
    backend = {
      count               = 3
      instance_type       = "GP1-S"
      image               = "ubuntu_noble"
      root_volume_size_gb = 50
      tags                = ["backend", "api"]

      cloud_init = <<-EOF
        #cloud-config
        packages: [docker.io]
      EOF
    }

    frontend = {
      count               = 2
      instance_type       = "DEV1-M"
      image               = "ubuntu_noble"
      root_volume_size_gb = 30
      tags                = ["frontend", "web"]
    }

    database = {
      count                  = 1
      instance_type          = "GP1-M"
      enable_backup_snapshot = true
      create_public_ip       = false

      # SBS volumes with configurable IOPS
      additional_volumes = [
        { size_gb = 200, type = "sbs_5k" },   # 5000 IOPS
        { size_gb = 100, type = "sbs_15k" },  # 15000 IOPS
      ]

      # Database connects to both networks
      private_networks = [
        scaleway_vpc_private_network.main.id,
        scaleway_vpc_private_network.data.id,
      ]

      # Per-group security rules (MERGED with global rules)
      # This group gets: SSH (global) + PostgreSQL (group-specific)
      security_group = {
        inbound_rules = [
          { protocol = "TCP", port = 5432, ip_range = "10.0.0.0/8" },
        ]
      }
    }
  }

  # HA placement
  placement_group = { policy_type = "max_availability" }

  # Global security rules (apply to shared SG + merged into per-group SGs)
  security_group = {
    inbound_rules = [
      { protocol = "TCP", port = 22, ip_range = "10.0.0.0/8" },
      { protocol = "TCP", port = 443 },
    ]
  }
}
```

## Upgrading from v2 to v3

v3.0.0 is a major release. Before editing the call, note the v2 values of the Project and the zone: the new defaults follow the provider, and a different Project or zone replaces every resource. Set `project_id` to the value of the v2 `project_id` output and `zone` to the v2 zone explicitly, then check that `tofu plan` shows no replacement.

| v2 | v3 |
|----|----|
| `organization_id`, `project_name` | removed; `project_id = "<uuid>"` (null = provider default project) |
| `zone` default `"fr-par-1"` | default `null` (provider default zone); set `zone = "fr-par-1"` if the provider zone differs |
| `create_ssh_key`, `ssh_public_key_file` | removed; `ssh_public_key = file("~/.ssh/id_ed25519.pub")` creates the key |
| `create_security_group`, `security_group_id`, `inbound_default_policy`, `outbound_default_policy`, `stateful`, `inbound_rules`, `outbound_rules` | `security_group = { id = ... }` to reuse a group, otherwise `security_group = { inbound_rules = [...] }` (same fields) |
| default `inbound_rules` (TCP 22 from `0.0.0.0/0`) | default `[]`: add `{ protocol = "TCP", port = 22, ip_range = "<cidr>" }` to `security_group.inbound_rules` to keep SSH |
| `create_placement_group`, `placement_group_id`, `placement_group_policy_type`, `placement_group_policy_mode` | `placement_group = {}` (create), `{ policy_type = "low_latency" }` or `{ id = "..." }`; the deprecated mode is dropped |
| `private_networks = [{ id = ..., ip_address = ... }]` (global and per group) | `private_networks = [<network id>]`; `ip_address` was never applied |
| global `public_ip_type` (`nat` accepted) | `public_ip_type` per group (`routed_ipv4` default, `routed_ipv6`); `nat` is rejected |
| group `create_security_group`, `security_group_id`, `inbound_default_policy`, `outbound_default_policy`, `stateful`, `inbound_rules`, `outbound_rules` | group `security_group = { ... }`, same shape as the global one |
| `root_volume_type = "b_ssd"` | rejected (the provider no longer supports it): use `l_ssd` or `sbs_volume` |
| `enable_backup_snapshot` rejected with `sbs_volume` | accepted: a block snapshot is created |
| outputs `project_id`, `group_security_group_ids`, `block_volumes`, `public_ips`, `private_ips` | removed: read `module.x.instances[k].public_ips` / `.private_ips`, `module.x.security_groups` and `module.x.volumes` (now every additional volume) |
| `instances[*].public_ip`, `.private_ip` | `public_ips`, `private_ips`: lists of addresses of every family |

New in v3: `enable_private_nic_security_group` and `enable_ipv6` per group, the `backup_snapshots` output, group tags (`group:<group>` and the group `tags`) on additional volumes and public IPs. Applying v3 updates the tags of existing volumes and IPs in place, switches the server from `ip_id` to `ip_ids` (the IP is not detached) and removes the default SSH rule if you relied on it.

### Private networks: existing NICs must be imported or re-attached

v2 attached networks with the inline `private_network` block of the server; v3 creates one `scaleway_instance_private_nic` per server and network (key `<server key>-pn-<NN>`, e.g. `web-00-pn-00`). No `moved` block can turn a nested block into a resource, and the server ignores changes to its `private_network` block from now on, so `tofu plan` will not detach the existing NICs but would try to attach a second one. Servers without a private network are unaffected. Pick one path before the first v3 apply:

1. **Import (recommended, no downtime).** Add one `import` block per server and network to the **root** module, using the NIC ID (`<zone>/<server id>/<nic id>` format as shown by `scw instance private-nic list` or the console):

   ```hcl
   import {
     to = module.compute.scaleway_instance_private_nic.this["web-00-pn-00"]
     id = "fr-par-1/<server id>/<nic id>"
   }
   ```

   The NIC keeps its MAC address and private IP. A second `tofu plan` is empty unless tags or `enable_private_nic_security_group` changed.
2. **Re-attach (downtime).** On v2.2.0 apply `private_networks = []` (this detaches the NICs), then upgrade and apply v3. The private network is unavailable meanwhile and the new NIC gets a new MAC address and possibly a different private IP.

Rolling back to v2: pin the previous tag after destroying the v3-only resources (IPv6 IPs, block snapshots and NICs created by v3).

## Security Group Architecture

This module uses a **two-tier security group architecture**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Security Group Architecture                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           SHARED SECURITY GROUP (name-shared-sg)          │   │
│  │                                                            │   │
│  │  Contains: Global security_group rules                     │   │
│  │  Applied to: All instances WITHOUT custom rules            │   │
│  │                                                            │   │
│  │  Examples: backend, frontend groups                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │        PER-GROUP SECURITY GROUPS (name-{group}-sg)        │   │
│  │                                                            │   │
│  │  Contains: Global rules + Group-specific rules (MERGED)    │   │
│  │  Created when: Group specifies custom inbound/outbound     │   │
│  │                                                            │   │
│  │  Example: database group with PostgreSQL rules             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### How it works

| Instance Group | Has Custom Rules? | Security Group Used | Rules Applied |
|---------------|-------------------|---------------------|---------------|
| `backend` | No | `name-shared-sg` | Global rules only |
| `frontend` | No | `name-shared-sg` | Global rules only |
| `database` | Yes | `name-database-sg` | Global + PostgreSQL rules |
| `cache` | Yes | `name-cache-sg` | Global + Redis rules |

### Outputs

```hcl
# Get the shared security group ID
module.compute.shared_security_group_id

# Get the security groups created by the module (key "shared" and one per group with custom rules)
module.compute.security_groups["database"].id
module.compute.security_groups
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.7 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.89 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.89 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [scaleway_block_snapshot.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/block_snapshot) | resource |
| [scaleway_block_volume.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/block_volume) | resource |
| [scaleway_iam_ssh_key.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_ssh_key) | resource |
| [scaleway_instance_ip.ipv6](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_ip) | resource |
| [scaleway_instance_ip.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_ip) | resource |
| [scaleway_instance_placement_group.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_placement_group) | resource |
| [scaleway_instance_private_nic.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_private_nic) | resource |
| [scaleway_instance_security_group.group](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_security_group) | resource |
| [scaleway_instance_security_group.shared](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_security_group) | resource |
| [scaleway_instance_security_group_rules.group](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_security_group_rules) | resource |
| [scaleway_instance_security_group_rules.shared](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_security_group_rules) | resource |
| [scaleway_instance_server.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_server) | resource |
| [scaleway_instance_snapshot.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_snapshot) | resource |
| [scaleway_instance_volume.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_volume) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_instances"></a> [instances](#input\_instances) | Map of instance groups to create. Each group can have different count, type, image, etc. A group security\_group follows the global security\_group shape; unset fields inherit the global value. | <pre>map(object({<br/>    count               = number<br/>    instance_type       = string<br/>    image               = optional(string, "ubuntu_noble")<br/>    root_volume_size_gb = optional(number, 20)<br/>    root_volume_type    = optional(string, "l_ssd")<br/>    # Only valid with root_volume_type = "sbs_volume" (5000 or 15000); null keeps the API default.<br/>    root_volume_sbs_iops = optional(number)<br/>    state                = optional(string, "started")<br/>    # Protects the servers against deletion through the Scaleway API; unprotect and apply before destroy.<br/>    enable_protection = optional(bool, false)<br/>    tags              = optional(list(string), [])<br/>    cloud_init        = optional(string)<br/>    user_data         = optional(map(string), {})<br/>    create_public_ip  = optional(bool, true)<br/>    public_ip_type    = optional(string, "routed_ipv4")<br/>    # Adds one routed_ipv6 IP per server next to the routed_ipv4 one.<br/>    enable_ipv6      = optional(bool, false)<br/>    private_networks = optional(list(string), [])<br/>    # Applies the security group resolved for the servers to their private NICs. With a<br/>    # default-drop inbound policy this blocks private traffic that no rule allows.<br/>    enable_private_nic_security_group = optional(bool, false)<br/>    # Every field is optional and null inherits the global security_group value.<br/>    # DEVIATION(terraform-variables): defaults to {} (all fields null) instead of null, so locals read the fields without try().<br/>    security_group = optional(object({<br/>      id                      = optional(string)<br/>      inbound_default_policy  = optional(string)<br/>      outbound_default_policy = optional(string)<br/>      stateful                = optional(bool)<br/>      inbound_rules = optional(list(object({<br/>        action     = optional(string, "accept")<br/>        protocol   = optional(string, "TCP")<br/>        port       = optional(number)<br/>        port_range = optional(string)<br/>        ip_range   = optional(string, "0.0.0.0/0")<br/>      })))<br/>      outbound_rules = optional(list(object({<br/>        action     = optional(string, "accept")<br/>        protocol   = optional(string, "TCP")<br/>        port       = optional(number)<br/>        port_range = optional(string)<br/>        ip_range   = optional(string, "0.0.0.0/0")<br/>      })))<br/>    }), {})<br/>    placement_group_id     = optional(string)<br/>    enable_backup_snapshot = optional(bool, false)<br/>    additional_volumes = optional(list(object({<br/>      size_gb = number<br/>      type    = optional(string, "sbs_5k")<br/>      iops    = optional(number)<br/>    })), [])<br/>    # Block volumes can only be attached to ONE instance at a time, so external_volume_ids<br/>    # is only valid when count <= 1. Enforced by precondition on scaleway_instance_server.this.<br/>    external_volume_ids = optional(list(string), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Workload name used as a prefix for resource naming and tagging. | `string` | n/a | yes |
| <a name="input_placement_group"></a> [placement\_group](#input\_placement\_group) | Shared placement group. Null creates none, {} creates one (policy\_type defaults to max\_availability), { id } reuses an existing group. policy\_type is low\_latency or max\_availability and applies only to a created group. | <pre>object({<br/>    id          = optional(string)<br/>    policy_type = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_private_networks"></a> [private\_networks](#input\_private\_networks) | IDs of the private networks attached to every instance whose group sets no private\_networks (one private NIC per server and network). | `list(string)` | `[]` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Scaleway Project ID where all resources are created. Null uses the provider default project. | `string` | `null` | no |
| <a name="input_security_group"></a> [security\_group](#input\_security\_group) | Shared security group. With id set, that existing group is used and nothing is created (rules cannot be combined with id); otherwise one is created. Inbound traffic is dropped unless inbound\_rules allow it: the default has no rule, so add SSH explicitly. | <pre>object({<br/>    id                      = optional(string)<br/>    inbound_default_policy  = optional(string, "drop")<br/>    outbound_default_policy = optional(string, "accept")<br/>    stateful                = optional(bool, true)<br/>    inbound_rules = optional(list(object({<br/>      action     = optional(string, "accept")<br/>      protocol   = optional(string, "TCP")<br/>      port       = optional(number)<br/>      port_range = optional(string)<br/>      ip_range   = optional(string, "0.0.0.0/0")<br/>    })), [])<br/>    outbound_rules = optional(list(object({<br/>      action     = optional(string, "accept")<br/>      protocol   = optional(string, "TCP")<br/>      port       = optional(number)<br/>      port_range = optional(string)<br/>      ip_range   = optional(string, "0.0.0.0/0")<br/>    })), [])<br/>  })</pre> | `{}` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key content (e.g. file("~/.ssh/id\_ed25519.pub")); the IAM SSH key is created when set. A public key is not a secret: it is sensitive only to keep it out of plan output, is not ephemeral because scaleway\_iam\_ssh\_key has no write-only argument, and is stored in state. Scaleway scopes the key to the Project and copies it to every Instance of the Project at boot. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Global tags applied to all resources. | `list(string)` | `[]` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Resource operation timeouts for create, update, and delete operations. | <pre>object({<br/>    create = optional(string, "10m")<br/>    update = optional(string, "10m")<br/>    delete = optional(string, "10m")<br/>  })</pre> | `{}` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | Scaleway zone (e.g., fr-par-1, nl-ams-1). Null uses the provider default zone. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backup_snapshots"></a> [backup\_snapshots](#output\_backup\_snapshots) | Root volume backup snapshots keyed by instance key with id, name and type ('instance' for l\_ssd roots, 'block' for sbs\_volume roots). |
| <a name="output_instances"></a> [instances](#output\_instances) | Map of all instances keyed by '<group>-<NN>' with id, name, type, state, zone, public\_ips and private\_ips (lists of addresses). |
| <a name="output_instances_by_group"></a> [instances\_by\_group](#output\_instances\_by\_group) | Instances grouped by their instance group name, each with id, name, public\_ips and private\_ips. |
| <a name="output_placement_group_id"></a> [placement\_group\_id](#output\_placement\_group\_id) | ID of the created placement group, or placement\_group.id when an existing group is reused (null when neither). |
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | Security groups created by the module (shared + per-group) keyed by 'shared' or group name, with id and full name. |
| <a name="output_shared_security_group_id"></a> [shared\_security\_group\_id](#output\_shared\_security\_group\_id) | ID of the shared security group, or security\_group.id when an existing group is reused. |
| <a name="output_ssh_key_id"></a> [ssh\_key\_id](#output\_ssh\_key\_id) | ID of the SSH key created by the module (null when ssh\_public\_key is not set). |
| <a name="output_volumes"></a> [volumes](#output\_volumes) | Map of additional volumes created by the module keyed '<instance key>-vol-<NN>' with id, name and type ('local' or 'sbs'). |
<!-- END_TF_DOCS -->

## Security Considerations

- The module is closed by default: the shared security group drops all inbound traffic and has no rule, so nothing (not even SSH) is reachable until you list rules in `security_group.inbound_rules`
- Restrict SSH and other management ports to specific IP ranges instead of `0.0.0.0/0`; `0.0.0.0/0` does not match IPv6, add `::/0` explicitly for dual stack servers
- Enable `stateful` security groups for automatic return traffic handling
- Private networks are unfiltered by default. Set `enable_private_nic_security_group = true` on a group to apply its security group to its private NICs. With the default `drop` inbound policy this blocks all private traffic that no rule allows: list the private CIDR rules (and ICMP if needed) first. Support may depend on the Instance type
- Groups with custom rules get a dedicated security group with merged rules (global + group-specific)
- Use `security_group = { id = ... }` at group level to attach an external security group instead of creating one

## SBS Root Volumes and Protected Servers

- `root_volume_type = "sbs_volume"` creates the root volume on SBS; `root_volume_sbs_iops` (`5000` or `15000`) is optional and only valid with it.
- `enable_backup_snapshot` works with both root types: `l_ssd` roots get an Instance snapshot, `sbs_volume` roots a block snapshot (see the `backup_snapshots` output).
- Changing an existing group from `l_ssd` to `sbs_volume` replaces its servers.
- Run `tofu init -upgrade` when your lock file pins a provider older than 2.88.0, which fixes applying IOPS to a new SBS root volume.
- `enable_protection = true` makes the Scaleway API reject deletion of the group's servers. Set it back to `false` and apply before destroying them.

## Resource Timeouts

Configure operation timeouts using the `timeouts` variable:

```hcl
module "compute" {
  source = "..."

  timeouts = {
    create = "20m"  # Instance creation (default: 10m)
    update = "15m"  # Instance updates (default: 10m)
    delete = "10m"  # Instance deletion (default: 10m)
  }

  # ... other configuration
}
```

Timeouts apply to instances (create, update, delete) and SBS block volumes (create, delete). Public IPs, private NICs, security groups, local volumes, snapshots (instance and block), the placement group and the SSH key keep the provider defaults.

## Lifecycle Protection

To protect critical resources from accidental deletion, use Terraform's `prevent_destroy` in your root module:

```hcl
# In your root module, after the module call:
resource "null_resource" "protect_database" {
  # Reference the database instances to create a dependency
  triggers = {
    instance_ids = join(",", [
      for k, v in module.compute.instances : v.id
      if startswith(k, "database-")
    ])
  }

  lifecycle {
    prevent_destroy = true
  }
}
```

Alternatively, for direct resource protection, fork the module and add:

```hcl
# In scaleway_instance_server.this resource:
lifecycle {
  prevent_destroy = true  # Add this line
}
```

### Ignoring External Tag Changes

The module has no input to ignore tag drift caused by external systems. `lifecycle.ignore_changes` cannot be driven by a variable, so this requires forking the module and adding `ignore_changes = [tags]` to the lifecycle block of the resource concerned.

## SSH Key

When `ssh_public_key` is set (for example `file("~/.ssh/id_ed25519.pub")`) the module creates one IAM SSH key; there is no separate switch or file input. Scaleway scopes IAM SSH keys to the Project and copies them to every Instance of the Project, not only the ones created by this module, when the Instance boots. The module creates the key before the servers so it is present at their first boot; for existing Instances, reboot them or run `scw-fetch-ssh-keys --upgrade`. The key is a public key: `ssh_public_key` is `sensitive` only to keep it out of plan output, and it is stored in state.

## Contributing

Changes are planned with [OpenSpec](https://github.com/Fission-AI/OpenSpec): `openspec/specs/` is the module's current contract and [AGENTS.md](AGENTS.md) routes to the engineering standards. Behaviour changes, new inputs, outputs or resources go through a change proposal (`/openspec-propose`) before any code.

1. Run `mise install` and `pre-commit install` once, and `mise run spec-setup` once per machine to register the standards stores.
2. Plan the change with `/openspec-propose`, implement it with `/openspec-apply-change`, then merge the specs with `/openspec-archive-change`.
3. Add or update tests in `tests/` (run them with `tofu test`).
4. Run `pre-commit run -a` and `mise run spec-validate`.
5. Write commit subjects that read as `CHANGELOG.md` lines: the file is generated by git-cliff (`mise run changelog`).

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg
[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io
[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.86-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/
[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-compute?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-compute/-/releases
