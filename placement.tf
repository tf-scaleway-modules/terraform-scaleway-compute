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

  tags = local.global_tags
}
