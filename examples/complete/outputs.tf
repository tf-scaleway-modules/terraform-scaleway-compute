output "instances" {
  description = "All instances with their details"
  value       = module.compute.instances
}

output "instances_by_group" {
  description = "Instances grouped by group name"
  value       = module.compute.instances_by_group
}

output "public_ips" {
  description = "Public IP addresses"
  value       = module.compute.public_ips
}

output "private_ips" {
  description = "Private IP addresses"
  value       = module.compute.private_ips
}

output "shared_security_group_id" {
  description = "Shared security group ID (applies to all instances without custom rules)"
  value       = module.compute.shared_security_group_id
}

output "group_security_group_ids" {
  description = "Security group IDs for groups with custom rules"
  value       = module.compute.group_security_group_ids
}

output "security_groups" {
  description = "All security groups (shared + per-group)"
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
