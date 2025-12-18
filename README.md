# Scaleway Compute Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]
[![Latest Release][release-badge]][release-url]

A Terraform module for creating and managing **Scaleway** Compute infrastructure.

## Usage Examples

A comprehensive examples available in the [`examples/`](examples/) directory:

- **[Minimal](examples/minimal/)** - Simplest configuration for quick start
- **[Complete](examples/complete/)** - Full-featured production setup

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.7 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.64 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.64 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_iam_ssh_key.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_ssh_key) | resource |
| [scaleway_instance_ip.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_ip) | resource |
| [scaleway_instance_placement_group.placement_group](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_placement_group) | resource |
| [scaleway_instance_security_group.sg01](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_security_group) | resource |
| [scaleway_instance_security_group_rules.sgrs01](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_security_group_rules) | resource |
| [scaleway_instance_server.node](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/instance_server) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_key"></a> [add\_key](#input\_add\_key) | True/False about adding an SSH Key | `string` | `true` | no |
| <a name="input_bucket_numbers"></a> [bucket\_numbers](#input\_bucket\_numbers) | n/a | `number` | `0` | no |
| <a name="input_cf_domain"></a> [cf\_domain](#input\_cf\_domain) | n/a | `string` | `"leminnov.tech"` | no |
| <a name="input_enable_bucket"></a> [enable\_bucket](#input\_enable\_bucket) | n/a | `string` | `true` | no |
| <a name="input_enable_cloudflare"></a> [enable\_cloudflare](#input\_enable\_cloudflare) | n/a | `bool` | `true` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Name of the environment | `string` | `"env-name"` | no |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | n/a | `number` | `1` | no |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | Name of node | `string` | `"node-name"` | no |
| <a name="input_private_key_path"></a> [private\_key\_path](#input\_private\_key\_path) | Path to the private key that will be used | `string` | `"~/.ssh/id_rsa"` | no |
| <a name="input_public_key_path"></a> [public\_key\_path](#input\_public\_key\_path) | Path to the public key that will be uploaded | `string` | `"~/.ssh/id_rsa.pub"` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | n/a | `number` | `80` | no |
| <a name="input_server_arch"></a> [server\_arch](#input\_server\_arch) | n/a | `string` | `"x86_64"` | no |
| <a name="input_server_image"></a> [server\_image](#input\_server\_image) | n/a | `string` | `"Ubuntu Bionic"` | no |
| <a name="input_server_type"></a> [server\_type](#input\_server\_type) | n/a | `string` | `"START1-S"` | no |
| <a name="input_use_placement_group"></a> [use\_placement\_group](#input\_use\_placement\_group) | True/False about using a placement group | `string` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_endpoint"></a> [bucket\_endpoint](#output\_bucket\_endpoint) | n/a |
| <a name="output_bucket_ids"></a> [bucket\_ids](#output\_bucket\_ids) | n/a |
| <a name="output_eip_ips"></a> [eip\_ips](#output\_eip\_ips) | n/a |
| <a name="output_key_id"></a> [key\_id](#output\_key\_id) | ID of the created SSH key |
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips) | n/a |
<!-- END_TF_DOCS -->

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind, express or implied. The authors and contributors are not responsible for any issues, damages, or losses arising from the use of this module. No official support is provided. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io

[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.63-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-vpc?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-vpc/-/releases
