output "key_id" {
  description = "ID of the created SSH key"
  value       = scaleway_iam_ssh_key.this.*.id
}

output "eip_ips" {
  value = scaleway_instance_ip.this.*.address
}

output "public_ips" {
  value = scaleway_instance_server.node.*.public_ip
}

output "bucket_ids" {
  value = scaleway_object_bucket.this.*.id
}

output "bucket_endpoint" {
  value = scaleway_object_bucket.this.*.endpoint
}
