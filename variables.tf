# ==============================================================================
# Organization & Project
# ==============================================================================

variable "organization_id" {
  description = "Scaleway Organization ID."
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, start with a letter, and be 2-63 characters."
  }
}

# ==============================================================================
# Global Configuration
# ==============================================================================

variable "zone" {
  description = "Scaleway zone (e.g., fr-par-1, nl-ams-1)."
  type        = string
  default     = "fr-par-1"
}

variable "tags" {
  description = "Global tags applied to all resources."
  type        = list(string)
  default     = []
}

# ==============================================================================
# Instances Configuration
# ==============================================================================

variable "instances" {
  description = "Map of instance groups to create. Each group can have different count, type, image, etc."
  type = map(object({
    count                  = number
    instance_type          = string
    image                  = optional(string, "ubuntu_noble")
    root_volume_size_gb    = optional(number, 20)
    root_volume_type       = optional(string, "l_ssd")
    state                  = optional(string, "started")
    tags                   = optional(list(string), [])
    cloud_init             = optional(string)
    user_data              = optional(map(string), {})
    create_public_ip       = optional(bool, true)
    private_network_id     = optional(string)
    security_group_id      = optional(string)
    placement_group_id     = optional(string)
    enable_backup_snapshot = optional(bool, false)
    additional_volumes = optional(list(object({
      size_gb = number
      type    = optional(string, "b_ssd")
    })), [])
  }))

  validation {
    condition = alltrue([
      for k, v in var.instances : v.count >= 0 && v.count <= 50
    ])
    error_message = "Instance count per group must be between 0 and 50."
  }
}

# ==============================================================================
# SSH Key Configuration
# ==============================================================================

variable "create_ssh_key" {
  description = "Create and upload an SSH key."
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key content."
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_public_key_file" {
  description = "Path to SSH public key file."
  type        = string
  default     = null
}

# ==============================================================================
# Security Group Configuration (Shared)
# ==============================================================================

variable "create_security_group" {
  description = "Create a shared security group for all instances."
  type        = bool
  default     = true
}

variable "security_group_id" {
  description = "ID of existing security group (when create_security_group is false)."
  type        = string
  default     = null
}

variable "inbound_default_policy" {
  description = "Default inbound policy: accept or drop."
  type        = string
  default     = "drop"
}

variable "outbound_default_policy" {
  description = "Default outbound policy: accept or drop."
  type        = string
  default     = "accept"
}

variable "stateful" {
  description = "Enable stateful security group."
  type        = bool
  default     = true
}

variable "inbound_rules" {
  description = "Inbound security group rules."
  type = list(object({
    action     = optional(string, "accept")
    protocol   = optional(string, "TCP")
    port       = optional(number)
    port_range = optional(string)
    ip_range   = optional(string, "0.0.0.0/0")
  }))
  default = [
    { protocol = "TCP", port = 22, ip_range = "0.0.0.0/0" }
  ]
}

variable "outbound_rules" {
  description = "Outbound security group rules."
  type = list(object({
    action     = optional(string, "accept")
    protocol   = optional(string, "TCP")
    port       = optional(number)
    port_range = optional(string)
    ip_range   = optional(string, "0.0.0.0/0")
  }))
  default = []
}

# ==============================================================================
# Placement Group Configuration (Shared)
# ==============================================================================

variable "create_placement_group" {
  description = "Create a shared placement group."
  type        = bool
  default     = false
}

variable "placement_group_id" {
  description = "ID of existing placement group."
  type        = string
  default     = null
}

variable "placement_group_policy_type" {
  description = "Placement policy: low_latency or max_availability."
  type        = string
  default     = "max_availability"
}

variable "placement_group_policy_mode" {
  description = "Placement mode: optional or enforced."
  type        = string
  default     = "optional"
}

# ==============================================================================
# Network Configuration (Shared)
# ==============================================================================

variable "private_network_id" {
  description = "Default private network ID for all instances."
  type        = string
  default     = null
}

variable "public_ip_type" {
  description = "Type of public IP: routed_ipv4, routed_ipv6, or nat."
  type        = string
  default     = "routed_ipv4"
}
