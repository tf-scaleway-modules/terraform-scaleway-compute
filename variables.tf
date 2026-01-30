# ==============================================================================
# Organization & Project
# ==============================================================================

variable "organization_id" {
  description = "Scaleway Organization ID."
  type        = string
}

variable "project_name" {
  description = "Scaleway Project name where all resources will be created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, start with a letter, and be 2-63 characters."
  }
}

variable "name" {
  description = "Name for resource naming and tagging."
  type        = string
}

# ==============================================================================
# Global Configuration
# ==============================================================================

variable "zone" {
  description = "Scaleway zone (e.g., fr-par-1, nl-ams-1)."
  type        = string
  default     = "fr-par-1"

  validation {
    condition     = can(regex("^(fr-par|nl-ams|pl-waw)-[1-3]$", var.zone))
    error_message = "Zone must be a valid Scaleway zone (e.g., fr-par-1, nl-ams-1, pl-waw-2)."
  }
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
    count               = number
    instance_type       = string
    image               = optional(string, "ubuntu_noble")
    root_volume_size_gb = optional(number, 20)
    root_volume_type    = optional(string, "l_ssd")
    state               = optional(string, "started")
    tags                = optional(list(string), [])
    cloud_init          = optional(string)
    user_data           = optional(map(string), {})
    create_public_ip    = optional(bool, true)
    private_networks = optional(list(object({
      id         = string           # Private network ID
      ip_address = optional(string) # Optional static IP in the private network
    })), [])
    # Security group configuration (per instance group)
    security_group_id       = optional(string) # Use existing security group ID (skips creation)
    create_security_group   = optional(bool)   # Create a security group for this group (default: use global setting)
    inbound_default_policy  = optional(string) # Default inbound policy: accept or drop
    outbound_default_policy = optional(string) # Default outbound policy: accept or drop
    stateful                = optional(bool)   # Enable stateful security group
    inbound_rules = optional(list(object({
      action     = optional(string, "accept")
      protocol   = optional(string, "TCP")
      port       = optional(number)
      port_range = optional(string)
      ip_range   = optional(string, "0.0.0.0/0")
    })))
    outbound_rules = optional(list(object({
      action     = optional(string, "accept")
      protocol   = optional(string, "TCP")
      port       = optional(number)
      port_range = optional(string)
      ip_range   = optional(string, "0.0.0.0/0")
    })))
    placement_group_id     = optional(string)
    enable_backup_snapshot = optional(bool, false)
    additional_volumes = optional(list(object({
      size_gb = number
      type    = optional(string, "sbs_5k") # sbs_5k, sbs_15k (IOPS tiers), or l_ssd (local)
      iops    = optional(number)           # Custom IOPS (only for SBS volumes)
    })), [])
    # IDs of externally created volumes to attach.
    # IMPORTANT: Only works when count <= 1. Block volumes can only be attached
    # to ONE instance at a time - they cannot be shared across multiple instances.
    external_volume_ids = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for k, v in var.instances : v.count >= 0 && v.count <= 50
    ])
    error_message = "Instance count per group must be between 0 and 50."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : can(regex("^[A-Z]+[0-9]+-[A-Z0-9]+$", v.instance_type))
    ])
    error_message = "Instance type must be a valid Scaleway format (e.g., DEV1-S, GP1-M, PRO2-XXS)."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : contains(["l_ssd", "b_ssd"], v.root_volume_type)
    ])
    error_message = "Root volume type must be 'l_ssd' or 'b_ssd'."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : contains(["started", "stopped", "standby"], v.state)
    ])
    error_message = "Instance state must be 'started', 'stopped', or 'standby'."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : alltrue([
        for vol in v.additional_volumes : contains(["l_ssd", "sbs_5k", "sbs_15k"], vol.type)
      ])
    ])
    error_message = "Additional volume type must be 'l_ssd', 'sbs_5k', or 'sbs_15k'."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : !(
        v.security_group_id != null && (v.inbound_rules != null || v.outbound_rules != null)
      )
    ])
    error_message = "Cannot specify both security_group_id and custom inbound_rules/outbound_rules. Use one or the other."
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

  validation {
    condition     = contains(["accept", "drop"], var.inbound_default_policy)
    error_message = "Inbound default policy must be 'accept' or 'drop'."
  }
}

variable "outbound_default_policy" {
  description = "Default outbound policy: accept or drop."
  type        = string
  default     = "accept"

  validation {
    condition     = contains(["accept", "drop"], var.outbound_default_policy)
    error_message = "Outbound default policy must be 'accept' or 'drop'."
  }
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

  validation {
    condition = alltrue([
      for rule in var.inbound_rules : contains(["TCP", "UDP", "ICMP", "ANY"], rule.protocol)
    ])
    error_message = "Inbound rule protocol must be 'TCP', 'UDP', 'ICMP', or 'ANY'."
  }

  validation {
    condition = alltrue([
      for rule in var.inbound_rules : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", rule.ip_range))
    ])
    error_message = "Inbound rule ip_range must be valid CIDR notation (e.g., '10.0.0.0/8', '0.0.0.0/0')."
  }

  validation {
    condition = alltrue([
      for rule in var.inbound_rules : !(rule.port != null && rule.port_range != null)
    ])
    error_message = "Inbound rule cannot specify both 'port' and 'port_range' - use one or the other."
  }
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

  validation {
    condition = alltrue([
      for rule in var.outbound_rules : contains(["TCP", "UDP", "ICMP", "ANY"], rule.protocol)
    ])
    error_message = "Outbound rule protocol must be 'TCP', 'UDP', 'ICMP', or 'ANY'."
  }

  validation {
    condition = alltrue([
      for rule in var.outbound_rules : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", rule.ip_range))
    ])
    error_message = "Outbound rule ip_range must be valid CIDR notation (e.g., '10.0.0.0/8', '0.0.0.0/0')."
  }

  validation {
    condition = alltrue([
      for rule in var.outbound_rules : !(rule.port != null && rule.port_range != null)
    ])
    error_message = "Outbound rule cannot specify both 'port' and 'port_range' - use one or the other."
  }
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

  validation {
    condition     = contains(["low_latency", "max_availability"], var.placement_group_policy_type)
    error_message = "Placement group policy type must be 'low_latency' or 'max_availability'."
  }
}

variable "placement_group_policy_mode" {
  description = "Placement mode: optional or enforced."
  type        = string
  default     = "optional"

  validation {
    condition     = contains(["optional", "enforced"], var.placement_group_policy_mode)
    error_message = "Placement group policy mode must be 'optional' or 'enforced'."
  }
}

# ==============================================================================
# Network Configuration (Shared)
# ==============================================================================

variable "private_networks" {
  description = "Default private networks for all instances. Each network can have an optional static IP."
  type = list(object({
    id         = string           # Private network ID
    ip_address = optional(string) # Optional static IP in the private network
  }))
  default = []
}

variable "public_ip_type" {
  description = "Type of public IP: routed_ipv4, routed_ipv6, or nat."
  type        = string
  default     = "routed_ipv4"

  validation {
    condition     = contains(["routed_ipv4", "routed_ipv6", "nat"], var.public_ip_type)
    error_message = "Public IP type must be 'routed_ipv4', 'routed_ipv6', or 'nat'."
  }
}

# ==============================================================================
# Lifecycle Configuration
# ==============================================================================

# tflint-ignore: terraform_unused_declarations
variable "ignore_tags_changes" {
  description = <<-EOT
    Ignore changes to tags made outside of Terraform. Useful when external systems add tags.
    NOTE: Due to Terraform limitations, this variable is for documentation purposes only.
    To actually ignore tag changes, modify the module source or use a wrapper module with
    lifecycle { ignore_changes = [tags] }.
  EOT
  type        = bool
  default     = false
}

variable "timeouts" {
  description = "Resource operation timeouts for create, update, and delete operations."
  type = object({
    create = optional(string, "10m")
    update = optional(string, "10m")
    delete = optional(string, "10m")
  })
  default = {}
}
