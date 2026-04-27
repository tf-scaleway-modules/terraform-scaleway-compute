# ==============================================================================
# Project
# ==============================================================================

output "project_id" {
  description = "Scaleway Project ID resolved from project_name via the account data source."
  value       = local.project_id
}

# ==============================================================================
# SSH Key
# ==============================================================================

output "ssh_key_id" {
  description = "ID of the SSH key created by the module (null when create_ssh_key is false)."
  value       = try(scaleway_iam_ssh_key.this[0].id, null)
}

# ==============================================================================
# Security Groups
# ==============================================================================

output "shared_security_group_id" {
  description = "ID of the shared security group, or var.security_group_id when create_security_group is false."
  value       = try(scaleway_instance_security_group.shared[0].id, var.security_group_id)
}

output "group_security_group_ids" {
  description = "Map of instance group names to their dedicated security group IDs (only groups with custom rules)."
  value       = { for k, v in scaleway_instance_security_group.group : k => v.id }
}

output "security_groups" {
  description = "All security groups (shared + per-group) keyed by name with id and full name."
  value = merge(
    try({ shared = { id = scaleway_instance_security_group.shared[0].id, name = scaleway_instance_security_group.shared[0].name } }, {}),
    { for k, v in scaleway_instance_security_group.group : k => { id = v.id, name = v.name } }
  )
}

# ==============================================================================
# Placement Group
# ==============================================================================

output "placement_group_id" {
  description = "ID of the shared placement group, or var.placement_group_id when create_placement_group is false."
  value       = try(scaleway_instance_placement_group.this[0].id, var.placement_group_id)
}

# ==============================================================================
# Volumes
# ==============================================================================

output "volumes" {
  description = "Map of additional local (l_ssd) volumes keyed by volume key."
  value       = { for k, v in scaleway_instance_volume.this : k => { id = v.id, name = v.name, type = "local" } }
}

output "block_volumes" {
  description = "Map of additional SBS block volumes keyed by volume key."
  value       = { for k, v in scaleway_block_volume.this : k => { id = v.id, name = v.name, type = "sbs" } }
}

# ==============================================================================
# Instances
# ==============================================================================

output "instances" {
  description = "Map of all instances keyed by '<group>-<index>' with id, name, type, state, zone, public_ip, private_ip."
  value = {
    for k, v in scaleway_instance_server.this : k => {
      id         = v.id
      name       = v.name
      type       = v.type
      state      = v.state
      zone       = v.zone
      public_ip  = try(v.public_ips[0].address, null)
      private_ip = try(v.private_ips[0], null)
    }
  }
}

output "instances_by_group" {
  description = "Instances grouped by their instance group name."
  value = {
    for group_name in distinct([for k, v in local.instances_flat : v.group_name]) :
    group_name => {
      for k, v in scaleway_instance_server.this : k => {
        id         = v.id
        name       = v.name
        public_ip  = try(v.public_ips[0].address, null)
        private_ip = try(v.private_ips[0], null)
      } if local.instances_flat[k].group_name == group_name
    }
  }
}

output "public_ips" {
  description = "Map of instance keys to public IP addresses."
  value       = { for k, v in scaleway_instance_server.this : k => try(v.public_ips[0].address, null) }
}

output "private_ips" {
  description = "Map of instance keys to private IP addresses."
  value       = { for k, v in scaleway_instance_server.this : k => try(v.private_ips[0], null) }
}
