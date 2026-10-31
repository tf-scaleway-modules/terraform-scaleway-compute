# Complete Example

Exercises every feature the module exposes — useful as both reference and test fixture.

## What this demonstrates

- **Multiple instance groups** — `backend`, `frontend`, `database`, `cache`, `bastion`, `worker`, `storage`, each with distinct types, images, and counts
- **Mixed root volume types** — `l_ssd` for performance-sensitive groups, `sbs_volume` (with IOPS and a block-snapshot backup) for `cache`
- **Cloud-init per group** — Docker, nginx, postgres, redis, fail2ban, NFS server bootstraps
- **Custom user_data** — key/value metadata alongside cloud-init
- **Two-tier security groups** — global `security_group` rules on the shared SG plus per-group `security_group` rules (`cache`, `storage`) that get merged with the globals into a dedicated SG
- **Multiple private networks** — `database` joins both `main` and `data` networks, one private NIC per server and network
- **Private NIC security group** — `storage` filters its private NICs with its security group (`enable_private_nic_security_group`), listing the private CIDR it needs
- **Dual stack** — `frontend` gets an IPv4 and an IPv6 public IP (`enable_ipv6`)
- **SBS block volumes** — `database`, `cache`, and `worker` get internal `sbs_5k` and `sbs_15k` volumes
- **External volume attachment** — `storage` group attaches a pre-existing `scaleway_block_volume` (only valid when `count <= 1`)
- **Backup snapshots** — `enable_backup_snapshot = true` on `database` (instance snapshot) and `cache` (block snapshot)
- **Placement group** — shared `max_availability` placement group (`placement_group = {}`)
- **SSH key upload** — `ssh_public_key = var.ssh_public_key`

## Usage

Update the placeholder UUIDs (`project_id`) before running, and pass your SSH public key:

```bash
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
tofu init
tofu plan
tofu apply
```

## Cleanup

```bash
tofu destroy
```
