# ==============================================================================
# Placement Group (Shared)
# ==============================================================================

resource "scaleway_instance_placement_group" "this" {
  count = local.create_placement_group ? 1 : 0

  name        = "${var.name}-pg"
  project_id  = var.project_id
  zone        = var.zone
  policy_type = coalesce(var.placement_group.policy_type, "max_availability")

  tags = local.global_tags
}
