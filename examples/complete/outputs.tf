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

output "security_group_id" {
  description = "Security group ID"
  value       = module.compute.security_group_id
}

output "placement_group_id" {
  description = "Placement group ID"
  value       = module.compute.placement_group_id
}

output "volumes" {
  description = "Additional volumes"
  value       = module.compute.volumes
}
