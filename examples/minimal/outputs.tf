output "instances" {
  description = "All instances"
  value       = module.compute.instances
}

output "public_ips" {
  description = "Public IPs"
  value       = module.compute.public_ips
}
