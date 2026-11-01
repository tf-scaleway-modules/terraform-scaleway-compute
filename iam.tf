# ==============================================================================
# SSH Key
# ==============================================================================

resource "scaleway_iam_ssh_key" "this" {
  # nonsensitive: only the presence of the key is revealed, never its content.
  count = nonsensitive(var.ssh_public_key != null) ? 1 : 0

  name       = "${var.name}-ssh-key"
  public_key = var.ssh_public_key
  project_id = var.project_id
}
