# Complete Example

Exercises every feature the module exposes — useful as both reference and test fixture.

## What this demonstrates

- **Multiple instance groups** — `backend`, `frontend`, `database`, `cache`, `bastion`, `worker`, `storage`, each with distinct types, images, and counts
- **Mixed root volume types** — `l_ssd` for performance-sensitive groups
- **Cloud-init per group** — Docker, nginx, postgres, redis, fail2ban, NFS server bootstraps
- **Custom user_data** — key/value metadata alongside cloud-init
- **Two-tier security groups** — global `inbound_rules`/`outbound_rules` on the shared SG plus per-group rules (`cache`, `storage`) that get merged with the globals into a dedicated SG
- **Multiple private networks** — `database` joins both `main` and `data` networks
- **SBS block volumes** — `database`, `cache`, and `worker` get internal `sbs_5k` and `sbs_15k` volumes
- **External volume attachment** — `storage` group attaches a pre-existing `scaleway_block_volume` (only valid when `count <= 1`)
- **Backup snapshots** — `enable_backup_snapshot = true` on `database`
- **Placement group** — shared `max_availability` placement group
- **SSH key upload** — `create_ssh_key = true` with `ssh_public_key_file`

## Usage

Update the placeholder UUIDs (`organization_id`, `project_id` on the VPC and external volume resources) before running:

```bash
tofu init
tofu plan
tofu apply
```

## Cleanup

```bash
tofu destroy
```
