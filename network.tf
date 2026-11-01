# ==============================================================================
# Public IP Addresses
# ==============================================================================

resource "scaleway_instance_ip" "this" {
  for_each = { for k, v in local.instances_flat : k => v if v.create_public_ip }

  project_id = var.project_id
  zone       = var.zone
  type       = each.value.public_ip_type

  lifecycle {
    create_before_destroy = true
  }

  tags = each.value.tags
}

# Dual stack: a separate resource keeps the address of the existing IPv4 IP.
resource "scaleway_instance_ip" "ipv6" {
  for_each = { for k, v in local.instances_flat : k => v if v.enable_ipv6 }

  project_id = var.project_id
  zone       = var.zone
  type       = "routed_ipv6"

  lifecycle {
    create_before_destroy = true
  }

  tags = each.value.tags
}

# ==============================================================================
# Private NICs (one per server and private network)
# ==============================================================================

resource "scaleway_instance_private_nic" "this" {
  for_each = local.private_nics

  server_id          = scaleway_instance_server.this[each.value.instance_key].id
  private_network_id = each.value.private_network_id
  security_group_id  = each.value.security_group_id
  zone               = var.zone

  tags = each.value.tags
}

# ==============================================================================
# Shared Security Group (applies to all instances by default)
# ==============================================================================

resource "scaleway_instance_security_group" "shared" {
  count = local.create_shared_security_group ? 1 : 0

  name                    = "${var.name}-shared-sg"
  description             = "Shared security group for ${var.name}"
  project_id              = var.project_id
  zone                    = var.zone
  inbound_default_policy  = var.security_group.inbound_default_policy
  outbound_default_policy = var.security_group.outbound_default_policy
  stateful                = var.security_group.stateful
  external_rules          = true

  lifecycle {
    create_before_destroy = true
  }

  tags = local.global_tags
}

resource "scaleway_instance_security_group_rules" "shared" {
  count = local.create_shared_security_group && (length(var.security_group.inbound_rules) > 0 || length(var.security_group.outbound_rules) > 0) ? 1 : 0

  security_group_id = scaleway_instance_security_group.shared[0].id

  dynamic "inbound_rule" {
    for_each = var.security_group.inbound_rules
    content {
      action     = inbound_rule.value.action
      protocol   = inbound_rule.value.protocol
      port       = inbound_rule.value.port
      port_range = inbound_rule.value.port_range
      ip_range   = inbound_rule.value.ip_range
    }
  }

  dynamic "outbound_rule" {
    for_each = var.security_group.outbound_rules
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
# Per-group SGs include MERGED rules: global + group-specific.

resource "scaleway_instance_security_group" "group" {
  for_each = local.security_groups_to_create

  name                    = each.value.name
  description             = "Security group for ${var.name} - ${each.key}"
  project_id              = var.project_id
  zone                    = var.zone
  inbound_default_policy  = each.value.inbound_default_policy
  outbound_default_policy = each.value.outbound_default_policy
  stateful                = each.value.stateful
  external_rules          = true

  lifecycle {
    create_before_destroy = true
  }

  tags = each.value.tags
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
