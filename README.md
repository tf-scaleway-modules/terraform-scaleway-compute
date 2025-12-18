# Scaleway Compute Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]
[![Latest Release][release-badge]][release-url]

A production-ready Terraform module for creating and managing **Scaleway** Compute infrastructure.

## Features

- **Compute Instances**: Create multiple instances with flexible configuration
- **Security Groups**: Configurable inbound/outbound rules with dynamic blocks
- **Private Networks (VPC)**: Optional VPC creation with IPv4/IPv6 subnets
- **Block Storage**: Support for additional volumes per instance
- **Placement Groups**: High availability or low latency configurations
- **Cloud-Init**: Full cloud-init and user data support
- **SSH Keys**: Automatic SSH key management
- **Backup Snapshots**: Optional snapshot creation for backups
- **Reserved IPs**: Static public IP allocation

## Usage Examples

Comprehensive examples are available in the [`examples/`](examples/) directory:

- **[Minimal](examples/minimal/)** - Simplest configuration for quick start
- **[Complete](examples/complete/)** - Full-featured production setup

### Quick Start

```hcl
module "compute" {
  source  = "git::https://gitlab.com/leminnov/terraform/modules/scaleway-compute.git"

  name        = "my-server"
  environment = "dev"

  instance_count = 1
  instance_type  = "DEV1-S"
  image          = "ubuntu_noble"

  inbound_rules = [
    {
      action   = "accept"
      protocol = "TCP"
      port     = 22
      ip_range = "0.0.0.0/0"
    }
  ]
}
```

### Production Setup

```hcl
module "compute" {
  source  = "git::https://gitlab.com/leminnov/terraform/modules/scaleway-compute.git"

  name        = "web-cluster"
  environment = "prod"
  zone        = "fr-par-1"

  # Multiple instances with HA placement
  instance_count              = 3
  instance_type               = "GP1-S"
  image                       = "ubuntu_noble"
  create_placement_group      = true
  placement_group_policy_type = "max_availability"

  # Private network
  create_private_network      = true
  private_network_ipv4_subnet = "10.0.0.0/24"

  # Additional storage
  additional_volumes = [
    { size_gb = 100, type = "b_ssd" }
  ]

  # Security rules
  inbound_default_policy = "drop"
  inbound_rules = [
    { protocol = "TCP", port = 22, ip_range = "10.0.0.0/8" },
    { protocol = "TCP", port = 443, ip_range = "0.0.0.0/0" },
  ]

  # Cloud-init
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    packages: [nginx]
  EOF
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.7 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.64 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | 2.65.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_iam_ssh_key.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_ssh_key) | resource |
| [scaleway_instance_ip.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_ip) | resource |
| [scaleway_instance_placement_group.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_placement_group) | resource |
| [scaleway_instance_security_group.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_security_group) | resource |
| [scaleway_instance_security_group_rules.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_security_group_rules) | resource |
| [scaleway_instance_server.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_server) | resource |
| [scaleway_instance_snapshot.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_snapshot) | resource |
| [scaleway_instance_volume.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_volume) | resource |
| [scaleway_account_project.project](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/account_project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_placement_group"></a> [create\_placement\_group](#input\_create\_placement\_group) | Create a shared placement group. | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Create a shared security group for all instances. | `bool` | `true` | no |
| <a name="input_create_ssh_key"></a> [create\_ssh\_key](#input\_create\_ssh\_key) | Create and upload an SSH key. | `bool` | `false` | no |
| <a name="input_inbound_default_policy"></a> [inbound\_default\_policy](#input\_inbound\_default\_policy) | Default inbound policy: accept or drop. | `string` | `"drop"` | no |
| <a name="input_inbound_rules"></a> [inbound\_rules](#input\_inbound\_rules) | Inbound security group rules. | <pre>list(object({<br/>    action     = optional(string, "accept")<br/>    protocol   = optional(string, "TCP")<br/>    port       = optional(number)<br/>    port_range = optional(string)<br/>    ip_range   = optional(string, "0.0.0.0/0")<br/>  }))</pre> | <pre>[<br/>  {<br/>    "ip_range": "0.0.0.0/0",<br/>    "port": 22,<br/>    "protocol": "TCP"<br/>  }<br/>]</pre> | no |
| <a name="input_instances"></a> [instances](#input\_instances) | Map of instance groups to create. Each group can have different count, type, image, etc. | <pre>map(object({<br/>    count                  = number<br/>    instance_type          = string<br/>    image                  = optional(string, "ubuntu_noble")<br/>    root_volume_size_gb    = optional(number, 20)<br/>    root_volume_type       = optional(string, "l_ssd")<br/>    state                  = optional(string, "started")<br/>    tags                   = optional(list(string), [])<br/>    cloud_init             = optional(string)<br/>    user_data              = optional(map(string), {})<br/>    create_public_ip       = optional(bool, true)<br/>    private_network_id     = optional(string)<br/>    security_group_id      = optional(string)<br/>    placement_group_id     = optional(string)<br/>    enable_backup_snapshot = optional(bool, false)<br/>    additional_volumes = optional(list(object({<br/>      size_gb = number<br/>      type    = optional(string, "b_ssd")<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Scaleway Organization ID. | `string` | n/a | yes |
| <a name="input_outbound_default_policy"></a> [outbound\_default\_policy](#input\_outbound\_default\_policy) | Default outbound policy: accept or drop. | `string` | `"accept"` | no |
| <a name="input_outbound_rules"></a> [outbound\_rules](#input\_outbound\_rules) | Outbound security group rules. | <pre>list(object({<br/>    action     = optional(string, "accept")<br/>    protocol   = optional(string, "TCP")<br/>    port       = optional(number)<br/>    port_range = optional(string)<br/>    ip_range   = optional(string, "0.0.0.0/0")<br/>  }))</pre> | `[]` | no |
| <a name="input_placement_group_id"></a> [placement\_group\_id](#input\_placement\_group\_id) | ID of existing placement group. | `string` | `null` | no |
| <a name="input_placement_group_policy_mode"></a> [placement\_group\_policy\_mode](#input\_placement\_group\_policy\_mode) | Placement mode: optional or enforced. | `string` | `"optional"` | no |
| <a name="input_placement_group_policy_type"></a> [placement\_group\_policy\_type](#input\_placement\_group\_policy\_type) | Placement policy: low\_latency or max\_availability. | `string` | `"max_availability"` | no |
| <a name="input_private_network_id"></a> [private\_network\_id](#input\_private\_network\_id) | Default private network ID for all instances. | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging. | `string` | n/a | yes |
| <a name="input_public_ip_type"></a> [public\_ip\_type](#input\_public\_ip\_type) | Type of public IP: routed\_ipv4, routed\_ipv6, or nat. | `string` | `"routed_ipv4"` | no |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | ID of existing security group (when create\_security\_group is false). | `string` | `null` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key content. | `string` | `null` | no |
| <a name="input_ssh_public_key_file"></a> [ssh\_public\_key\_file](#input\_ssh\_public\_key\_file) | Path to SSH public key file. | `string` | `null` | no |
| <a name="input_stateful"></a> [stateful](#input\_stateful) | Enable stateful security group. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Global tags applied to all resources. | `list(string)` | `[]` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | Scaleway zone (e.g., fr-par-1, nl-ams-1). | `string` | `"fr-par-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instances"></a> [instances](#output\_instances) | Map of all instances with their details. |
| <a name="output_instances_by_group"></a> [instances\_by\_group](#output\_instances\_by\_group) | Instances grouped by their group name. |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | Scaleway Organization ID. |
| <a name="output_placement_group_id"></a> [placement\_group\_id](#output\_placement\_group\_id) | ID of the shared placement group. |
| <a name="output_private_ips"></a> [private\_ips](#output\_private\_ips) | Map of instance keys to private IPs. |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | Scaleway Project ID. |
| <a name="output_project_name"></a> [project\_name](#output\_project\_name) | Project name. |
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips) | Map of instance keys to public IPs. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the shared security group. |
| <a name="output_ssh_key_id"></a> [ssh\_key\_id](#output\_ssh\_key\_id) | ID of the SSH key. |
| <a name="output_volumes"></a> [volumes](#output\_volumes) | Map of additional volumes. |
<!-- END_TF_DOCS -->

## Security Considerations

- Default inbound policy is `drop` - only explicitly allowed traffic is permitted
- SSH access is restricted by default - consider limiting to specific IP ranges
- Enable `stateful` security groups for automatic return traffic handling
- Use private networks for inter-instance communication

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg
[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io
[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.64-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/
[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-compute?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-compute/-/releases
