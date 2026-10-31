# ==============================================================================
# Local Values
# ==============================================================================

locals {
  # Default tags
  default_tags = ["terraform", "managed", "project:${var.name}"]
  global_tags  = distinct(concat(local.default_tags, var.tags))

  # Shared placement group: null = none, {} = create, { id } = existing
  create_placement_group = var.placement_group != null && var.placement_group.id == null
  placement_group_id     = local.create_placement_group ? scaleway_instance_placement_group.this[0].id : try(var.placement_group.id, null)

  # Shared security group ID (applies to all instances by default)
  create_shared_security_group = var.security_group.id == null
  shared_security_group_id     = local.create_shared_security_group ? scaleway_instance_security_group.shared[0].id : var.security_group.id

  # Per-group security groups (only created when group has custom rules)
  # These groups get MERGED rules: global rules + group-specific rules
  security_groups_to_create = {
    for group_name, group in var.instances : group_name => {
      name                    = "${var.name}-${group_name}-sg"
      inbound_default_policy  = coalesce(group.security_group.inbound_default_policy, var.security_group.inbound_default_policy)
      outbound_default_policy = coalesce(group.security_group.outbound_default_policy, var.security_group.outbound_default_policy)
      stateful                = coalesce(group.security_group.stateful, var.security_group.stateful)
      # Merge global rules with group-specific rules
      inbound_rules  = distinct(concat(var.security_group.inbound_rules, coalesce(group.security_group.inbound_rules, [])))
      outbound_rules = distinct(concat(var.security_group.outbound_rules, coalesce(group.security_group.outbound_rules, [])))
      tags           = distinct(concat(local.global_tags, ["group:${group_name}"], group.tags))
    }
    # Only create group-specific SG if group has custom rules AND no external security group
    if group.count > 0 && group.security_group.id == null && (group.security_group.inbound_rules != null || group.security_group.outbound_rules != null)
  }

  # Flatten instances map into individual instances
  # Creates: { "backend-00" = {...}, "backend-01" = {...}, "frontend-00" = {...}, ... }
  instances_flat = merge([
    for group_name, group in var.instances : {
      for idx in range(group.count) :
      "${group_name}-${format("%02d", idx)}" => {
        group_name        = group_name
        index             = idx
        name              = "${var.name}-${group_name}-${format("%02d", idx)}"
        instance_type     = group.instance_type
        image             = group.image
        root_volume_size  = group.root_volume_size_gb
        root_volume_type  = group.root_volume_type
        root_volume_iops  = group.root_volume_sbs_iops
        enable_protection = group.enable_protection
        state             = group.state
        tags              = distinct(concat(local.global_tags, ["group:${group_name}"], group.tags))
        cloud_init        = group.cloud_init
        user_data         = group.user_data
        create_public_ip  = group.create_public_ip
        public_ip_type    = group.public_ip_type
        enable_ipv6       = group.enable_ipv6
        # Private networks (group-specific or global)
        private_networks           = length(group.private_networks) > 0 ? group.private_networks : var.private_networks
        enable_private_nic_sg      = group.enable_private_nic_security_group
        external_security_group_id = group.security_group.id
        has_group_security_group   = group.security_group.id == null && contains(keys(local.security_groups_to_create), group_name)
        placement_group_id         = group.placement_group_id != null ? group.placement_group_id : local.placement_group_id
        enable_backup              = group.enable_backup_snapshot
        additional_volumes         = group.additional_volumes
        external_volume_ids        = group.external_volume_ids
      }
    }
  ]...)

  # Security group priority: external ID > per-group SG (merged rules) > shared SG
  server_security_group_ids = {
    for k, v in local.instances_flat : k => (
      v.external_security_group_id != null ? v.external_security_group_id :
      v.has_group_security_group ? scaleway_instance_security_group.group[v.group_name].id :
      local.shared_security_group_id
    )
  }

  # One private NIC per server and network, keyed <server key>-pn-<NN>
  private_nics = merge([
    for instance_key, instance in local.instances_flat : {
      for idx, network_id in instance.private_networks :
      "${instance_key}-pn-${format("%02d", idx)}" => {
        instance_key       = instance_key
        private_network_id = network_id
        security_group_id  = instance.enable_private_nic_sg ? local.server_security_group_ids[instance_key] : null
        tags               = instance.tags
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
        tags         = instance.tags
      }
    }
  ]...)

  # Separate SBS volumes from local volumes
  sbs_volumes   = { for k, v in local.volumes_flat : k => v if v.is_sbs }
  local_volumes = { for k, v in local.volumes_flat : k => v if !v.is_sbs }

  # Addresses of every family per server; private ones come from the NICs because
  # the server attribute is stale until refreshed after a NIC attach
  server_public_ips = {
    for k, v in scaleway_instance_server.this : k => [for ip in v.public_ips : ip.address]
  }
  server_private_ips = {
    for k in keys(local.instances_flat) : k => flatten([
      for nic_key, nic in scaleway_instance_private_nic.this :
      [for ip in nic.private_ips : ip.address] if local.private_nics[nic_key].instance_key == k
    ])
  }

  # Backup snapshots follow the root volume type
  instance_snapshots = { for k, v in local.instances_flat : k => v if v.enable_backup && v.root_volume_type == "l_ssd" }
  block_snapshots    = { for k, v in local.instances_flat : k => v if v.enable_backup && v.root_volume_type == "sbs_volume" }
}
