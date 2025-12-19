# ==============================================================================
# Local Values
# ==============================================================================

locals {
  # Project ID from data source
  project_id = data.scaleway_account_project.project.id

  # Default tags
  default_tags = ["terraform", "managed", "project:${var.project_name}"]
  global_tags  = distinct(concat(local.default_tags, var.tags))

  # SSH key resolution
  ssh_public_key_content = var.ssh_public_key != null ? var.ssh_public_key : (
    var.ssh_public_key_file != null ? file(var.ssh_public_key_file) : null
  )

  # Shared placement group ID
  placement_group_id = var.create_placement_group ? scaleway_instance_placement_group.this[0].id : var.placement_group_id

  # Default private networks (from global var)
  default_private_networks = var.private_networks

  # Shared security group ID (applies to all instances by default)
  shared_security_group_id = var.create_security_group ? scaleway_instance_security_group.shared[0].id : var.security_group_id

  # Per-group security groups (only created when group has custom rules)
  # These groups get MERGED rules: global rules + group-specific rules
  security_groups_to_create = {
    for group_name, group in var.instances : group_name => {
      name                    = "${var.project_name}-${group_name}-sg"
      inbound_default_policy  = coalesce(group.inbound_default_policy, var.inbound_default_policy)
      outbound_default_policy = coalesce(group.outbound_default_policy, var.outbound_default_policy)
      stateful                = coalesce(group.stateful, var.stateful)
      # Merge global rules with group-specific rules
      inbound_rules  = distinct(concat(var.inbound_rules, coalesce(group.inbound_rules, [])))
      outbound_rules = distinct(concat(var.outbound_rules, coalesce(group.outbound_rules, [])))
      tags           = distinct(concat(local.global_tags, ["group:${group_name}"], group.tags))
    }
    # Only create group-specific SG if group has custom rules AND no external security_group_id
    if group.count > 0 && group.security_group_id == null && (group.inbound_rules != null || group.outbound_rules != null)
  }

  # Flatten instances map into individual instances
  # Creates: { "backend-0" = {...}, "backend-1" = {...}, "frontend-0" = {...}, ... }
  instances_flat = merge([
    for group_name, group in var.instances : {
      for idx in range(group.count) :
      "${group_name}-${format("%02d", idx)}" => {
        group_name       = group_name
        index            = idx
        name             = "${var.project_name}-${group_name}-${format("%02d", idx)}"
        instance_type    = group.instance_type
        image            = group.image
        root_volume_size = group.root_volume_size_gb
        root_volume_type = group.root_volume_type
        state            = group.state
        tags             = distinct(concat(local.global_tags, ["group:${group_name}"], group.tags))
        cloud_init       = group.cloud_init
        user_data        = group.user_data
        create_public_ip = group.create_public_ip
        # Private networks (instance-specific or default)
        private_networks = length(group.private_networks) > 0 ? group.private_networks : local.default_private_networks
        # Security group priority: external ID > per-group SG > shared SG
        external_security_group_id = group.security_group_id
        has_group_security_group   = group.security_group_id == null && contains(keys(local.security_groups_to_create), group_name)
        placement_group_id         = coalesce(group.placement_group_id, local.placement_group_id)
        enable_backup              = group.enable_backup_snapshot
        additional_volumes         = group.additional_volumes
        external_volume_ids        = group.external_volume_ids
      }
    }
  ]...)

  # Flatten additional volumes for all instances
  volumes_flat = merge([
    for instance_key, instance in local.instances_flat : {
      for vol_idx, vol in instance.additional_volumes :
      "${instance_key}-vol-${format("%02d", vol_idx)}" => {
        instance_key = instance_key
        name         = "${instance.name}-vol-${format("%02d", vol_idx)}"
        size_gb      = vol.size_gb
        type         = vol.type
        iops         = vol.iops
        is_sbs       = startswith(vol.type, "sbs_") # SBS volumes use scaleway_block_volume
      }
    }
  ]...)

  # Separate SBS volumes from local volumes
  sbs_volumes   = { for k, v in local.volumes_flat : k => v if v.is_sbs }
  local_volumes = { for k, v in local.volumes_flat : k => v if !v.is_sbs }

  # Count of public IPs needed
  public_ip_instances = { for k, v in local.instances_flat : k => v if v.create_public_ip }
}
