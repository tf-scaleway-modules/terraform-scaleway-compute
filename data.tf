# data "scaleway_instance_image" "image" {
#   count = var.node_count > 0 ? 1 : 0

#   architecture = var.server_arch
#   name         = var.server_image
# }
