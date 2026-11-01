output "instances" {
  description = "All instances with their details"
  value       = module.compute.instances
}

output "instances_by_group" {
  description = "Instances grouped by group name"
  value       = module.compute.instances_by_group
}

output "shared_security_group_id" {
  description = "Shared security group ID (applies to all instances without custom rules)"
  value       = module.compute.shared_security_group_id
}

output "security_groups" {
  description = "Security groups created by the module (shared + per-group)"
  value       = module.compute.security_groups
}

output "placement_group_id" {
  description = "Placement group ID"
  value       = module.compute.placement_group_id
}

output "volumes" {
  description = "Additional volumes"
  value       = module.compute.volumes
}

output "backup_snapshots" {
  description = "Root volume backup snapshots"
  value       = module.compute.backup_snapshots
}
