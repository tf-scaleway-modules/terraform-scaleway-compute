# ==============================================================================
# Required - Workload Identity and Instance Groups
# ==============================================================================

variable "name" {
  description = "Workload name used as a prefix for resource naming and tagging."
  type        = string
}

variable "instances" {
  description = "Map of instance groups to create. Each group can have different count, type, image, etc. A group security_group follows the global security_group shape; unset fields inherit the global value."
  type = map(object({
    count               = number
    instance_type       = string
    image               = optional(string, "ubuntu_noble")
    root_volume_size_gb = optional(number, 20)
    root_volume_type    = optional(string, "l_ssd")
    # Only valid with root_volume_type = "sbs_volume" (5000 or 15000); null keeps the API default.
    root_volume_sbs_iops = optional(number)
    state                = optional(string, "started")
    # Protects the servers against deletion through the Scaleway API; unprotect and apply before destroy.
    enable_protection = optional(bool, false)
    tags              = optional(list(string), [])
    cloud_init        = optional(string)
    user_data         = optional(map(string), {})
    create_public_ip  = optional(bool, true)
    public_ip_type    = optional(string, "routed_ipv4")
    # Adds one routed_ipv6 IP per server next to the routed_ipv4 one.
    enable_ipv6      = optional(bool, false)
    private_networks = optional(list(string), [])
    # Applies the security group resolved for the servers to their private NICs. With a
    # default-drop inbound policy this blocks private traffic that no rule allows.
    enable_private_nic_security_group = optional(bool, false)
    # Every field is optional and null inherits the global security_group value.
    # DEVIATION(terraform-variables): defaults to {} (all fields null) instead of null, so locals read the fields without try().
    security_group = optional(object({
      id                      = optional(string)
      inbound_default_policy  = optional(string)
      outbound_default_policy = optional(string)
      stateful                = optional(bool)
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
    }), {})
    placement_group_id     = optional(string)
    enable_backup_snapshot = optional(bool, false)
    additional_volumes = optional(list(object({
      size_gb = number
      type    = optional(string, "sbs_5k")
      iops    = optional(number)
    })), [])
    # Block volumes can only be attached to ONE instance at a time, so external_volume_ids
    # is only valid when count <= 1. Enforced by precondition on scaleway_instance_server.this.
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
      for k, v in var.instances : contains(["l_ssd", "sbs_volume"], v.root_volume_type)
    ])
    error_message = "Root volume type must be 'l_ssd' or 'sbs_volume'."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : v.root_volume_sbs_iops == null || v.root_volume_type == "sbs_volume"
    ])
    error_message = "root_volume_sbs_iops requires root_volume_type 'sbs_volume'."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : v.root_volume_sbs_iops == null || contains([5000, 15000], v.root_volume_sbs_iops)
    ])
    error_message = "root_volume_sbs_iops must be 5000 or 15000."
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
      for k, v in var.instances : contains(["routed_ipv4", "routed_ipv6"], v.public_ip_type)
    ])
    error_message = "Public IP type must be 'routed_ipv4' or 'routed_ipv6'."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : !v.enable_ipv6 || (v.create_public_ip && v.public_ip_type == "routed_ipv4")
    ])
    error_message = "enable_ipv6 requires create_public_ip = true and public_ip_type = 'routed_ipv4'."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : length(v.private_networks) <= 8
    ])
    error_message = "At most 8 private networks can be attached to an instance."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : !(
        v.security_group.id != null && (v.security_group.inbound_rules != null || v.security_group.outbound_rules != null)
      )
    ])
    error_message = "Cannot specify both security_group.id and custom inbound_rules/outbound_rules. Use one or the other."
  }

  validation {
    condition = alltrue([
      for v in values(var.instances) : alltrue([
        for rule in concat(coalesce(v.security_group.inbound_rules, []), coalesce(v.security_group.outbound_rules, [])) :
        contains(["TCP", "UDP", "ICMP", "ANY"], rule.protocol)
      ])
    ])
    error_message = "Security group rule protocol must be 'TCP', 'UDP', 'ICMP', or 'ANY'."
  }

  validation {
    condition = alltrue([
      for v in values(var.instances) : alltrue([
        for rule in concat(coalesce(v.security_group.inbound_rules, []), coalesce(v.security_group.outbound_rules, [])) :
        can(cidrhost(rule.ip_range, 0))
      ])
    ])
    error_message = "Security group rule ip_range must be a valid IPv4 or IPv6 CIDR (e.g., '10.0.0.0/8', '::/0')."
  }

  validation {
    condition = alltrue([
      for v in values(var.instances) : alltrue([
        for rule in concat(coalesce(v.security_group.inbound_rules, []), coalesce(v.security_group.outbound_rules, [])) :
        !(rule.port != null && rule.port_range != null)
      ])
    ])
    error_message = "Security group rule cannot specify both 'port' and 'port_range' - use one or the other."
  }

  validation {
    condition = alltrue([
      for v in values(var.instances) : alltrue([
        for policy in [v.security_group.inbound_default_policy, v.security_group.outbound_default_policy] :
        policy == null || contains(["accept", "drop"], policy)
      ])
    ])
    error_message = "Security group default policies must be 'accept' or 'drop'."
  }
}

# ==============================================================================
# Global Configuration
# ==============================================================================

variable "project_id" {
  description = "Scaleway Project ID where all resources are created. Null uses the provider default project."
  type        = string
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.project_id))
    error_message = "project_id must be a UUID or null."
  }
}

variable "zone" {
  description = "Scaleway zone (e.g., fr-par-1, nl-ams-1). Null uses the provider default zone."
  type        = string
  default     = null

  validation {
    condition     = var.zone == null || can(regex("^(fr-par|nl-ams|pl-waw)-[1-3]$", var.zone))
    error_message = "Zone must be a valid Scaleway zone (e.g., fr-par-1, nl-ams-1, pl-waw-2)."
  }
}

variable "tags" {
  description = "Global tags applied to all resources."
  type        = list(string)
  default     = []
}

# ==============================================================================
# SSH Key Configuration
# ==============================================================================

variable "ssh_public_key" {
  description = "SSH public key content (e.g. file(\"~/.ssh/id_ed25519.pub\")); the IAM SSH key is created when set. A public key is not a secret: it is sensitive only to keep it out of plan output, is not ephemeral because scaleway_iam_ssh_key has no write-only argument, and is stored in state. Scaleway scopes the key to the Project and copies it to every Instance of the Project at boot."
  type        = string
  default     = null
  sensitive   = true
}

# ==============================================================================
# Security Group Configuration (Shared)
# ==============================================================================

variable "security_group" {
  description = "Shared security group. With id set, that existing group is used and nothing is created (rules cannot be combined with id); otherwise one is created. Inbound traffic is dropped unless inbound_rules allow it: the default has no rule, so add SSH explicitly."
  type = object({
    id                      = optional(string)
    inbound_default_policy  = optional(string, "drop")
    outbound_default_policy = optional(string, "accept")
    stateful                = optional(bool, true)
    inbound_rules = optional(list(object({
      action     = optional(string, "accept")
      protocol   = optional(string, "TCP")
      port       = optional(number)
      port_range = optional(string)
      ip_range   = optional(string, "0.0.0.0/0")
    })), [])
    outbound_rules = optional(list(object({
      action     = optional(string, "accept")
      protocol   = optional(string, "TCP")
      port       = optional(number)
      port_range = optional(string)
      ip_range   = optional(string, "0.0.0.0/0")
    })), [])
  })
  default = {}

  validation {
    condition = alltrue([
      for rule in concat(var.security_group.inbound_rules, var.security_group.outbound_rules) :
      contains(["TCP", "UDP", "ICMP", "ANY"], rule.protocol)
    ])
    error_message = "Security group rule protocol must be 'TCP', 'UDP', 'ICMP', or 'ANY'."
  }

  validation {
    condition = alltrue([
      for rule in concat(var.security_group.inbound_rules, var.security_group.outbound_rules) :
      can(cidrhost(rule.ip_range, 0))
    ])
    error_message = "Security group rule ip_range must be a valid IPv4 or IPv6 CIDR (e.g., '10.0.0.0/8', '::/0')."
  }

  validation {
    condition = alltrue([
      for rule in concat(var.security_group.inbound_rules, var.security_group.outbound_rules) :
      !(rule.port != null && rule.port_range != null)
    ])
    error_message = "Security group rule cannot specify both 'port' and 'port_range' - use one or the other."
  }

  validation {
    condition = alltrue([
      for policy in [var.security_group.inbound_default_policy, var.security_group.outbound_default_policy] :
      contains(["accept", "drop"], policy)
    ])
    error_message = "Security group default policies must be 'accept' or 'drop'."
  }

  validation {
    condition = !(
      var.security_group.id != null && (length(var.security_group.inbound_rules) > 0 || length(var.security_group.outbound_rules) > 0)
    )
    error_message = "Cannot specify both security_group.id and custom inbound_rules/outbound_rules. Use one or the other."
  }
}

# ==============================================================================
# Placement Group Configuration (Shared)
# ==============================================================================

variable "placement_group" {
  description = "Shared placement group. Null creates none, {} creates one (policy_type defaults to max_availability), { id } reuses an existing group. policy_type is low_latency or max_availability and applies only to a created group."
  type = object({
    id          = optional(string)
    policy_type = optional(string)
  })
  default = null

  validation {
    condition     = var.placement_group == null || var.placement_group.policy_type == null || contains(["low_latency", "max_availability"], var.placement_group.policy_type)
    error_message = "placement_group.policy_type must be 'low_latency' or 'max_availability'."
  }

  validation {
    condition     = var.placement_group == null || !(var.placement_group.id != null && var.placement_group.policy_type != null)
    error_message = "placement_group.policy_type applies only to a created placement group; do not combine it with placement_group.id."
  }
}

# ==============================================================================
# Network Configuration (Shared)
# ==============================================================================

variable "private_networks" {
  description = "IDs of the private networks attached to every instance whose group sets no private_networks (one private NIC per server and network)."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.private_networks) <= 8
    error_message = "At most 8 private networks can be attached to an instance."
  }
}

# ==============================================================================
# Lifecycle Configuration
# ==============================================================================

variable "timeouts" {
  description = "Resource operation timeouts for create, update, and delete operations."
  type = object({
    create = optional(string, "10m")
    update = optional(string, "10m")
    delete = optional(string, "10m")
  })
  default = {}
}
