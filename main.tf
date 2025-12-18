resource "scaleway_iam_ssh_key" "this" {
  count      = var.add_key == "true" ? 1 : 0
  name       = "${var.env_name}-${var.node_name}"
  public_key = file(var.public_key_path)
}

resource "scaleway_instance_ip" "this" {
  count = var.node_count
}

resource "scaleway_instance_security_group" "sg01" {
  name                    = "sg-${var.env_name}"
  description             = "Security Group used for the environement ${var.env_name}"
  inbound_default_policy  = "accept" //drop
  outbound_default_policy = "accept"
  external_rules          = true
}

resource "scaleway_instance_security_group_rules" "sgrs01" {
  security_group_id = scaleway_instance_security_group.sg01.id

  inbound_rule {
    action   = "accept"
    port     = 22
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 80
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 443
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 6443
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 2376
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 2379
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 2380
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 8472
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 9099
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 10250
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 10254
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 30000
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 30001
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 30002
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    port     = 3389
    ip_range = "0.0.0.0/0"
  }

  dynamic "inbound_rule" {
    for_each = scaleway_instance_ip.this.*.address

    content {
      action = "accept"
      ip     = inbound_rule.value
    }
  }

}

resource "scaleway_instance_placement_group" "placement_group" {
  count = var.use_placement_group == "true" ? 1 : 0

  name        = "${var.env_name}-placement-group"
  policy_type = "low_latency"
  policy_mode = "optional"
}

resource "scaleway_instance_server" "node" {
  count = var.node_count

  name = "${var.env_name}-${var.node_name}-${count.index}"

  image = var.server_image // BUG as the returned ID is not recognized: data.scaleway_instance_image.image[0].id
  type  = var.server_type

  ip_id = scaleway_instance_ip.this[count.index].id

  security_group_id = scaleway_instance_security_group.sg01.id

  placement_group_id = var.use_placement_group == "true" ? scaleway_instance_placement_group.placement_group[0].id : null

  root_volume {
    size_in_gb            = var.root_volume_size
    delete_on_termination = true
  }

  tags = [
    var.env_name,
    "${var.node_name}-${count.index}"
  ]

  depends_on = [
    scaleway_iam_ssh_key.this,
    scaleway_instance_ip.this,
    scaleway_instance_security_group.sg01,
    scaleway_instance_security_group_rules.sgrs01,
    scaleway_instance_placement_group.placement_group
  ]
}
