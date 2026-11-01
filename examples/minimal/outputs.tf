output "instances" {
  description = "All instances with their public and private addresses"
  value       = module.compute.instances
}
