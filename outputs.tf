# ==============================================================================
# SSH Key
# ==============================================================================

output "ssh_key_id" {
  description = "ID of the SSH key created by the module (null when ssh_public_key is not set)."
  value       = one(scaleway_iam_ssh_key.this[*].id)
}

# ==============================================================================
# Security Groups
# ==============================================================================

output "shared_security_group_id" {
  description = "ID of the shared security group, or security_group.id when an existing group is reused."
  value       = local.shared_security_group_id
}

output "security_groups" {
  description = "Security groups created by the module (shared + per-group) keyed by 'shared' or group name, with id and full name."
  value = merge(
    { for sg in scaleway_instance_security_group.shared : "shared" => { id = sg.id, name = sg.name } },
    { for k, v in scaleway_instance_security_group.group : k => { id = v.id, name = v.name } }
  )
}

# ==============================================================================
# Placement Group
# ==============================================================================

output "placement_group_id" {
  description = "ID of the created placement group, or placement_group.id when an existing group is reused (null when neither)."
  value       = local.placement_group_id
}

# ==============================================================================
# Volumes
# ==============================================================================

output "volumes" {
  description = "Map of additional volumes created by the module keyed '<instance key>-vol-<NN>' with id, name and type ('local' or 'sbs')."
  value = merge(
    { for k, v in scaleway_instance_volume.this : k => { id = v.id, name = v.name, type = "local" } },
    { for k, v in scaleway_block_volume.this : k => { id = v.id, name = v.name, type = "sbs" } },
  )
}

# ==============================================================================
# Instances
# ==============================================================================

output "instances" {
  description = "Map of all instances keyed by '<group>-<NN>' with id, name, type, state, zone, public_ips and private_ips (lists of addresses)."
  value = {
    for k, v in scaleway_instance_server.this : k => {
      id          = v.id
      name        = v.name
      type        = v.type
      state       = v.state
      zone        = v.zone
      public_ips  = local.server_public_ips[k]
      private_ips = local.server_private_ips[k]
    }
  }
}

output "instances_by_group" {
  description = "Instances grouped by their instance group name, each with id, name, public_ips and private_ips."
  value = {
    for group_name in distinct([for k, v in local.instances_flat : v.group_name]) :
    group_name => {
      for k, v in scaleway_instance_server.this : k => {
        id          = v.id
        name        = v.name
        public_ips  = local.server_public_ips[k]
        private_ips = local.server_private_ips[k]
      } if local.instances_flat[k].group_name == group_name
    }
  }
}

# ==============================================================================
# Backup Snapshots
# ==============================================================================

output "backup_snapshots" {
  description = "Root volume backup snapshots keyed by instance key with id, name and type ('instance' for l_ssd roots, 'block' for sbs_volume roots)."
  value = merge(
    { for k, v in scaleway_instance_snapshot.this : k => { id = v.id, name = v.name, type = "instance" } },
    { for k, v in scaleway_block_snapshot.this : k => { id = v.id, name = v.name, type = "block" } },
  )
}
