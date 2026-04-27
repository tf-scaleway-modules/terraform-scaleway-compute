# ==============================================================================
# Additional Block Volumes - SBS (Scaleway Block Storage)
# ==============================================================================

resource "scaleway_block_volume" "this" {
  for_each = local.sbs_volumes

  name       = each.value.name
  project_id = local.project_id
  zone       = var.zone
  iops       = each.value.iops != null ? each.value.iops : (each.value.type == "sbs_15k" ? 15000 : 5000)
  size_in_gb = each.value.size_gb

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
  }

  tags = local.global_tags
}

# ==============================================================================
# Additional Block Volumes - Local (l_ssd)
# ==============================================================================

resource "scaleway_instance_volume" "this" {
  for_each = local.local_volumes

  name       = each.value.name
  project_id = local.project_id
  zone       = var.zone
  type       = each.value.type
  size_in_gb = each.value.size_gb

  tags = local.global_tags
}
