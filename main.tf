# ==============================================================================
# Compute Instances
# ==============================================================================

resource "scaleway_instance_server" "this" {
  for_each = local.instances_flat

  name       = each.value.name
  project_id = local.project_id
  zone       = var.zone
  type       = each.value.instance_type
  image      = each.value.image
  state      = each.value.state

  ip_id = each.value.create_public_ip ? scaleway_instance_ip.this[each.key].id : null

  # Security group priority: external ID > per-group SG (merged rules) > shared SG
  security_group_id = (
    each.value.external_security_group_id != null ? each.value.external_security_group_id :
    each.value.has_group_security_group ? scaleway_instance_security_group.group[each.value.group_name].id :
    local.shared_security_group_id
  )
  placement_group_id = each.value.placement_group_id

  additional_volume_ids = concat(
    [
      for vol_key, vol in local.local_volumes :
      scaleway_instance_volume.this[vol_key].id
      if vol.instance_key == each.key
    ],
    [
      for vol_key, vol in local.sbs_volumes :
      scaleway_block_volume.this[vol_key].id
      if vol.instance_key == each.key
    ],
    each.value.external_volume_ids
  )

  user_data = each.value.cloud_init != null ? merge(
    each.value.user_data,
    { "cloud-init" = each.value.cloud_init }
  ) : (length(each.value.user_data) > 0 ? each.value.user_data : null)

  root_volume {
    size_in_gb            = each.value.root_volume_size
    volume_type           = each.value.root_volume_type
    delete_on_termination = true
  }

  dynamic "private_network" {
    for_each = each.value.private_networks
    content {
      pn_id = private_network.value.id
    }
  }

  depends_on = [
    scaleway_iam_ssh_key.this,
    scaleway_instance_security_group.shared,
    scaleway_instance_security_group_rules.shared,
    scaleway_instance_security_group.group,
    scaleway_instance_security_group_rules.group,
    scaleway_instance_placement_group.this,
    scaleway_instance_volume.this,
    scaleway_block_volume.this,
  ]

  lifecycle {
    precondition {
      condition     = length(each.value.external_volume_ids) == 0 || var.instances[each.value.group_name].count <= 1
      error_message = "External volumes can only be used when instance group count is 1. Block volumes cannot be shared across multiple instances."
    }
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  tags = each.value.tags
}

# ==============================================================================
# Instance Snapshots (Backup)
# ==============================================================================

resource "scaleway_instance_snapshot" "this" {
  for_each = { for k, v in local.instances_flat : k => v if v.enable_backup }

  name       = "${each.value.name}-snapshot"
  project_id = local.project_id
  zone       = var.zone
  volume_id  = scaleway_instance_server.this[each.key].root_volume[0].volume_id

  depends_on = [scaleway_instance_server.this]

  tags = each.value.tags
}
