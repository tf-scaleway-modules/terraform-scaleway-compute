# ==============================================================================
# SSH Key
# ==============================================================================

resource "scaleway_iam_ssh_key" "this" {
  count = var.create_ssh_key ? 1 : 0

  name       = "${var.name}-ssh-key"
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
# Shared Security Group (applies to all instances by default)
# ==============================================================================

resource "scaleway_instance_security_group" "shared" {
  count = var.create_security_group ? 1 : 0

  name                    = "${var.name}-shared-sg"
  description             = "Shared security group for ${var.name}"
  project_id              = local.project_id
  zone                    = var.zone
  inbound_default_policy  = var.inbound_default_policy
  outbound_default_policy = var.outbound_default_policy
  stateful                = var.stateful
  external_rules          = true
  tags                    = local.global_tags
}

resource "scaleway_instance_security_group_rules" "shared" {
  count = var.create_security_group && (length(var.inbound_rules) > 0 || length(var.outbound_rules) > 0) ? 1 : 0

  security_group_id = scaleway_instance_security_group.shared[0].id

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
# Per-Group Security Groups (for groups with custom rules)
# ==============================================================================
# These security groups include MERGED rules: global + group-specific

resource "scaleway_instance_security_group" "group" {
  for_each = local.security_groups_to_create

  name                    = each.value.name
  description             = "Security group for ${var.name} - ${each.key}"
  project_id              = local.project_id
  zone                    = var.zone
  inbound_default_policy  = each.value.inbound_default_policy
  outbound_default_policy = each.value.outbound_default_policy
  stateful                = each.value.stateful
  external_rules          = true
  tags                    = each.value.tags
}

resource "scaleway_instance_security_group_rules" "group" {
  for_each = {
    for group_name, sg in local.security_groups_to_create : group_name => sg
    if length(sg.inbound_rules) > 0 || length(sg.outbound_rules) > 0
  }

  security_group_id = scaleway_instance_security_group.group[each.key].id

  dynamic "inbound_rule" {
    for_each = each.value.inbound_rules
    content {
      action     = inbound_rule.value.action
      protocol   = inbound_rule.value.protocol
      port       = inbound_rule.value.port
      port_range = inbound_rule.value.port_range
      ip_range   = inbound_rule.value.ip_range
    }
  }

  dynamic "outbound_rule" {
    for_each = each.value.outbound_rules
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

  name        = "${var.name}-pg"
  project_id  = local.project_id
  zone        = var.zone
  policy_type = var.placement_group_policy_type
  policy_mode = var.placement_group_policy_mode
  tags        = local.global_tags
}

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
  tags       = local.global_tags
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
  # Priority: external ID > per-group SG (with merged rules) > shared SG
  security_group_id = (
    each.value.external_security_group_id != null ? each.value.external_security_group_id :
    each.value.has_group_security_group ? scaleway_instance_security_group.group[each.value.group_name].id :
    local.shared_security_group_id
  )
  placement_group_id = each.value.placement_group_id

  # Root volume
  root_volume {
    size_in_gb            = each.value.root_volume_size
    volume_type           = each.value.root_volume_type
    delete_on_termination = true
  }

  # Additional volumes (internal l_ssd, internal SBS, and external volumes)
  additional_volume_ids = concat(
    # Internal local volumes (l_ssd)
    [
      for vol_key, vol in local.local_volumes :
      scaleway_instance_volume.this[vol_key].id
      if vol.instance_key == each.key
    ],
    # Internal SBS block volumes
    [
      for vol_key, vol in local.sbs_volumes :
      scaleway_block_volume.this[vol_key].id
      if vol.instance_key == each.key
    ],
    # External volumes (created outside the module)
    each.value.external_volume_ids
  )

  # Private networks (supports multiple)
  dynamic "private_network" {
    for_each = each.value.private_networks
    content {
      pn_id = private_network.value.id
      # Only set ip_address if explicitly provided (static IP)
      # Omit for DHCP assignment
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
    scaleway_instance_security_group.shared,
    scaleway_instance_security_group_rules.shared,
    scaleway_instance_security_group.group,
    scaleway_instance_security_group_rules.group,
    scaleway_instance_placement_group.this,
    scaleway_instance_volume.this,
    scaleway_block_volume.this,
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
