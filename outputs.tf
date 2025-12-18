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
      public_ip  = v.public_ip
      private_ip = v.private_ip
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
        public_ip  = v.public_ip
        private_ip = v.private_ip
      } if local.instances_flat[k].group_name == group_name
    }
  }
}

output "public_ips" {
  description = "Map of instance keys to public IPs."
  value       = { for k, v in scaleway_instance_server.this : k => v.public_ip }
}

output "private_ips" {
  description = "Map of instance keys to private IPs."
  value       = { for k, v in scaleway_instance_server.this : k => v.private_ip }
}

# ==============================================================================
# Security Group Outputs
# ==============================================================================

output "security_group_id" {
  description = "ID of the shared security group."
  value       = try(scaleway_instance_security_group.this[0].id, var.security_group_id)
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
  description = "Map of additional volumes."
  value       = { for k, v in scaleway_instance_volume.this : k => { id = v.id, name = v.name } }
}
