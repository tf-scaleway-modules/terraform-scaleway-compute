# ==============================================================================
# SSH Key
# ==============================================================================

resource "scaleway_iam_ssh_key" "this" {
  count = var.create_ssh_key ? 1 : 0

  name       = "${var.name}-ssh-key"
  public_key = local.ssh_public_key_content
  project_id = local.project_id

  lifecycle {
    precondition {
      condition     = var.ssh_public_key != null || var.ssh_public_key_file != null
      error_message = "SSH key creation requires either ssh_public_key or ssh_public_key_file to be provided."
    }
  }
}
