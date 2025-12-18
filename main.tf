# ==============================================================================
# SSH Key
# ==============================================================================

resource "scaleway_iam_ssh_key" "this" {
  count = var.create_ssh_key ? 1 : 0

  name       = "${var.project_name}-ssh-key"
  public_key = local.ssh_public_key_content
  project_id = local.project_id
}

# ==============================================================================
# Public IP Addresses
# ==============================================================================

resource "scaleway_instance_ip" "this" {
  for_each = local.public_ip_instances

  project_id = local.project_id
  zone       = var.zone
  type       = var.public_ip_type
  tags       = each.value.tags
}

# ==============================================================================
# Security Group (Shared)
# ==============================================================================

resource "scaleway_instance_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name                    = "${var.project_name}-sg"
  description             = "Security group for ${var.project_name}"
  project_id              = local.project_id
  zone                    = var.zone
  inbound_default_policy  = var.inbound_default_policy
  outbound_default_policy = var.outbound_default_policy
  stateful                = var.stateful
  external_rules          = true
  tags                    = local.global_tags
}

resource "scaleway_instance_security_group_rules" "this" {
  count = var.create_security_group && (length(var.inbound_rules) > 0 || length(var.outbound_rules) > 0) ? 1 : 0

  security_group_id = scaleway_instance_security_group.this[0].id

  dynamic "inbound_rule" {
    for_each = var.inbound_rules
    content {
      action     = inbound_rule.value.action
      protocol   = inbound_rule.value.protocol
      port       = inbound_rule.value.port
      port_range = inbound_rule.value.port_range
      ip_range   = inbound_rule.value.ip_range
    }
  }

  dynamic "outbound_rule" {
    for_each = var.outbound_rules
    content {
      action     = outbound_rule.value.action
      protocol   = outbound_rule.value.protocol
      port       = outbound_rule.value.port
      port_range = outbound_rule.value.port_range
      ip_range   = outbound_rule.value.ip_range
    }
  }
}

# ==============================================================================
# Placement Group (Shared)
# ==============================================================================

resource "scaleway_instance_placement_group" "this" {
  count = var.create_placement_group ? 1 : 0

  name        = "${var.project_name}-pg"
  project_id  = local.project_id
  zone        = var.zone
  policy_type = var.placement_group_policy_type
  policy_mode = var.placement_group_policy_mode
  tags        = local.global_tags
}

# ==============================================================================
# Additional Block Volumes
# ==============================================================================

resource "scaleway_instance_volume" "this" {
  for_each = local.volumes_flat

  name       = each.value.name
  project_id = local.project_id
  zone       = var.zone
  type       = each.value.type
  size_in_gb = each.value.size_gb
  tags       = local.global_tags
}

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

  # Public IP
  ip_id = each.value.create_public_ip ? scaleway_instance_ip.this[each.key].id : null

  # Security & Placement
  security_group_id  = each.value.security_group_id
  placement_group_id = each.value.placement_group_id

  # Root volume
  root_volume {
    size_in_gb            = each.value.root_volume_size
    volume_type           = each.value.root_volume_type
    delete_on_termination = true
  }

  # Additional volumes
  additional_volume_ids = [
    for vol_key, vol in local.volumes_flat :
    scaleway_instance_volume.this[vol_key].id
    if vol.instance_key == each.key
  ]

  # Private network
  dynamic "private_network" {
    for_each = each.value.private_network_id != null ? [1] : []
    content {
      pn_id = each.value.private_network_id
    }
  }

  # User data / cloud-init
  user_data = each.value.cloud_init != null ? merge(
    each.value.user_data,
    { "cloud-init" = each.value.cloud_init }
  ) : (length(each.value.user_data) > 0 ? each.value.user_data : null)

  tags = each.value.tags

  depends_on = [
    scaleway_iam_ssh_key.this,
    scaleway_instance_security_group.this,
    scaleway_instance_security_group_rules.this,
    scaleway_instance_placement_group.this,
    scaleway_instance_volume.this,
  ]
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
  tags       = each.value.tags

  depends_on = [scaleway_instance_server.this]
}
