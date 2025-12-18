output "instance_ids" {
  description = "IDs of the created instances"
  value       = module.compute.instance_ids
}

output "instance_names" {
  description = "Names of the created instances"
  value       = module.compute.instance_names
}

output "public_ips" {
  description = "Public IP addresses of the instances"
  value       = module.compute.instance_public_ips
}

output "private_ips" {
  description = "Private IP addresses of the instances"
  value       = module.compute.instance_private_ips
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.compute.security_group_id
}

output "private_network_id" {
  description = "ID of the private network"
  value       = module.compute.private_network_id
}

output "placement_group_id" {
  description = "ID of the placement group"
  value       = module.compute.placement_group_id
}

output "instances" {
  description = "Full instance details"
  value       = module.compute.instances
}
