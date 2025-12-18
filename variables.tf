variable "env_name" {
  type        = string
  description = "Name of the environment"
  default     = "env-name"
}

variable "node_name" {
  type        = string
  description = "Name of node"
  default     = "node-name"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "add_key" {
  description = "True/False about adding an SSH Key"
  type        = string
  default     = true
}

variable "public_key_path" {
  description = "Path to the public key that will be uploaded"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to the private key that will be used"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "use_placement_group" {
  description = "True/False about using a placement group"
  type        = string
  default     = false
}

variable "server_arch" {
  type    = string
  default = "x86_64"
}

variable "server_image" {
  type    = string
  default = "Ubuntu Bionic"
}

variable "server_type" {
  type    = string
  default = "START1-S"
}

variable "root_volume_size" {
  type    = number
  default = 80
}

variable "enable_cloudflare" {
  type    = bool
  default = true
}

variable "cf_domain" {
  type    = string
  default = "leminnov.tech"
}

variable "enable_bucket" {
  type    = string
  default = true
}

variable "bucket_numbers" {
  type    = number
  default = 0
}
