# ==============================================================================
# Compute Instances
# ==============================================================================

resource "scaleway_instance_server" "this" {
  for_each = local.instances_flat

  name       = each.value.name
  project_id = var.project_id
  zone       = var.zone
  type       = each.value.instance_type
  image      = each.value.image
  state      = each.value.state
  protected  = each.value.enable_protection

  ip_ids = concat(
    each.value.create_public_ip ? [scaleway_instance_ip.this[each.key].id] : [],
    each.value.enable_ipv6 ? [scaleway_instance_ip.ipv6[each.key].id] : [],
  )

  security_group_id  = local.server_security_group_ids[each.key]
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
    sbs_iops              = each.value.root_volume_iops
    delete_on_termination = true
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
    # scaleway_instance_private_nic owns the attachments; the server read refills this block.
    ignore_changes = [private_network]

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
# Backup Snapshots of the root volume
# ==============================================================================

resource "scaleway_instance_snapshot" "this" {
  for_each = local.instance_snapshots

  name       = "${each.value.name}-snapshot"
  project_id = var.project_id
  zone       = var.zone
  volume_id  = scaleway_instance_server.this[each.key].root_volume[0].volume_id

  tags = each.value.tags
}

resource "scaleway_block_snapshot" "this" {
  for_each = local.block_snapshots

  name       = "${each.value.name}-snapshot"
  project_id = var.project_id
  zone       = var.zone
  volume_id  = scaleway_instance_server.this[each.key].root_volume[0].volume_id

  tags = each.value.tags
}
