# ==============================================================================
# Project Outputs
# ==============================================================================

output "organization_id" {
  description = "Scaleway Organization ID."
  value       = var.organization_id
}

output "project_id" {
  description = "Scaleway Project ID."
  value       = local.project_id
}

output "project_name" {
  description = "Project name."
  value       = var.project_name
}

# ==============================================================================
# Instance Outputs
# ==============================================================================

output "instances" {
  description = "Map of all instances with their details."
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
  description = "Instances grouped by their group name."
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
  description = "Map of instance keys to public IPs."
  value       = { for k, v in scaleway_instance_server.this : k => try(v.public_ips[0].address, null) }
}

output "private_ips" {
  description = "Map of instance keys to private IPs."
  value       = { for k, v in scaleway_instance_server.this : k => try(v.private_ips[0], null) }
}

# ==============================================================================
# Security Group Outputs
# ==============================================================================

output "shared_security_group_id" {
  description = "ID of the shared security group (applies to all instances without custom rules)."
  value       = try(scaleway_instance_security_group.shared[0].id, var.security_group_id)
}

output "group_security_group_ids" {
  description = "Map of instance group names to their dedicated security group IDs (only groups with custom rules)."
  value       = { for k, v in scaleway_instance_security_group.group : k => v.id }
}

output "security_groups" {
  description = "All security groups (shared + per-group) with full details."
  value = merge(
    try({ shared = { id = scaleway_instance_security_group.shared[0].id, name = scaleway_instance_security_group.shared[0].name } }, {}),
    { for k, v in scaleway_instance_security_group.group : k => { id = v.id, name = v.name } }
  )
}

# ==============================================================================
# Placement Group Outputs
# ==============================================================================

output "placement_group_id" {
  description = "ID of the shared placement group."
  value       = try(scaleway_instance_placement_group.this[0].id, var.placement_group_id)
}

# ==============================================================================
# SSH Key Outputs
# ==============================================================================

output "ssh_key_id" {
  description = "ID of the SSH key."
  value       = try(scaleway_iam_ssh_key.this[0].id, null)
}

# ==============================================================================
# Volume Outputs
# ==============================================================================

output "volumes" {
  description = "Map of additional volumes (local l_ssd volumes)."
  value       = { for k, v in scaleway_instance_volume.this : k => { id = v.id, name = v.name, type = "local" } }
}

output "block_volumes" {
  description = "Map of SBS block volumes."
  value       = { for k, v in scaleway_block_volume.this : k => { id = v.id, name = v.name, type = "sbs" } }
}
