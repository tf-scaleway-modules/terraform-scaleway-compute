variable "ssh_public_key" {
  description = "SSH public key content to register as an IAM SSH key, for example the content of ~/.ssh/id_ed25519.pub."
  type        = string
}
