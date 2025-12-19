# ==============================================================================
# Complete Example - All Features Demonstrated
# ==============================================================================
#
# This example demonstrates ALL available features and variables of the module:
# - Multiple instance groups with different configurations
# - All instance-level options (volumes, cloud-init, user_data, state, etc.)
# - SSH key management
# - Security group with inbound/outbound rules
# - Placement group for high availability
# - Multiple private networks
# - SBS block storage (internal volumes)
# - External volume attachment
# - Backup snapshots
#
# ==============================================================================

# ==============================================================================
# VPC Private Networks
# ==============================================================================

# Main application network
resource "scaleway_vpc_private_network" "main" {
  name       = "complete-example-main"
  project_id = "d9191cb0-d164-47ec-8d04-2b1dd8dad3eb"
  region     = "fr-par"
  tags       = ["terraform", "managed", "complete-example", "main"]
}

# Database/storage network (isolated)
resource "scaleway_vpc_private_network" "data" {
  name       = "complete-example-data"
  project_id = "d9191cb0-d164-47ec-8d04-2b1dd8dad3eb"
  region     = "fr-par"
  tags       = ["terraform", "managed", "complete-example", "data"]
}

# ==============================================================================
# External Block Volumes (created outside the module)
# ==============================================================================

# External volumes for worker instances (one per instance since block volumes
# can only be attached to ONE instance at a time - they cannot be shared)
resource "scaleway_block_volume" "worker_external" {
  count = 4 # One per worker instance

  name       = "complete-example-worker-external-${format("%02d", count.index)}"
  project_id = "d9191cb0-d164-47ec-8d04-2b1dd8dad3eb"
  zone       = "fr-par-1"
  iops       = 5000
  size_in_gb = 50
  tags       = ["terraform", "managed", "complete-example", "external", "worker"]
}

# ==============================================================================
# Compute Module
# ==============================================================================

module "compute" {
  source = "../../"

  # ============================================================================
  # Organization & Project (Required)
  # ============================================================================

  organization_id = "f3d8393e-008a-4fb2-a4ff-81b6fe5c01b0"
  project_name    = "default"
  zone            = "fr-par-1"

  # Global tags applied to ALL resources
  tags = ["production", "ecommerce", "team:platform"]

  # ============================================================================
  # Instance Groups
  # ============================================================================
  #
  # Each group can have completely different configurations.
  # Instances are named: {project_name}-{group_name}-{index}
  # Example: ecommerce-platform-backend-00, ecommerce-platform-backend-01, etc.

  instances = {

    # --------------------------------------------------------------------------
    # Backend API Servers (3 instances)
    # --------------------------------------------------------------------------
    backend = {
      count         = 0
      instance_type = "GP1-S"
      image         = "ubuntu_noble"

      # Root volume configuration
      root_volume_size_gb = 50
      root_volume_type    = "l_ssd" # Local SSD for performance

      # Instance state: started, stopped, standby
      state = "started"

      # Group-specific tags (merged with global tags)
      tags = ["backend", "api", "tier:application"]

      # Cloud-init configuration
      cloud_init = <<-EOF
        #cloud-config
        package_update: true
        package_upgrade: true
        packages:
          - docker.io
          - docker-compose
          - htop
          - curl
        runcmd:
          - systemctl enable docker
          - systemctl start docker
          - usermod -aG docker ubuntu
      EOF

      # Custom user_data (key-value pairs)
      user_data = {
        "app-version" = "v2.1.0"
        "environment" = "production"
      }

      # Public IP enabled (default)
      create_public_ip = true
    }

    # --------------------------------------------------------------------------
    # Frontend Web Servers (4 instances)
    # --------------------------------------------------------------------------
    frontend = {
      count         = 0
      instance_type = "DEV1-M"
      image         = "ubuntu_noble"

      root_volume_size_gb = 30
      root_volume_type    = "l_ssd"
      state               = "started"

      tags = ["frontend", "web", "tier:presentation"]

      cloud_init = <<-EOF
        #cloud-config
        package_update: true
        packages:
          - nginx
          - certbot
          - python3-certbot-nginx
        runcmd:
          - systemctl enable nginx
          - systemctl start nginx
        write_files:
          - path: /etc/nginx/conf.d/health.conf
            content: |
              server {
                listen 8080;
                location /health {
                  return 200 'OK';
                }
              }
      EOF

      create_public_ip = true
    }

    # --------------------------------------------------------------------------
    # Database Server (1 instance with additional volumes and backup)
    # --------------------------------------------------------------------------
    database = {
      count         = 0
      instance_type = "GP1-M"
      image         = "ubuntu_noble"

      root_volume_size_gb = 50
      root_volume_type    = "l_ssd"
      state               = "started"

      tags = ["database", "postgres", "tier:data"]

      # Additional SBS block volumes for data storage
      additional_volumes = [
        { size_gb = 200, type = "sbs_5k" },  # Data volume (5000 IOPS)
        { size_gb = 100, type = "sbs_15k" }, # WAL/logs volume (15000 IOPS)
      ]

      # Database instances connect to BOTH networks (main + data)
      # This demonstrates multiple private network attachment
      private_networks = [
        { id = scaleway_vpc_private_network.main.id },
        { id = scaleway_vpc_private_network.data.id },
      ]

      # Enable backup snapshots for data protection
      enable_backup_snapshot = true

      cloud_init = <<-EOF
        #cloud-config
        package_update: true
        packages:
          - postgresql-16
          - postgresql-contrib-16
        runcmd:
          - systemctl enable postgresql
          - systemctl start postgresql
      EOF

      # Database doesn't need public IP (accessed via private network)
      create_public_ip = false
    }

    # --------------------------------------------------------------------------
    # Cache Servers (2 instances)
    # --------------------------------------------------------------------------
    cache = {
      count         = 2
      instance_type = "DEV1-S"
      image         = "ubuntu_noble"

      root_volume_size_gb = 20
      root_volume_type    = "l_ssd"
      state               = "started"

      tags = ["cache", "redis", "tier:caching"]

      # Additional SBS block volumes for data storage
      additional_volumes = [
        { size_gb = 20, type = "sbs_5k" },  # Data volume (5000 IOPS)
        { size_gb = 10, type = "sbs_15k" }, # WAL/logs volume (15000 IOPS)
      ]

      cloud_init = <<-EOF
        #cloud-config
        package_update: true
        packages:
          - redis-server
        runcmd:
          - systemctl enable redis-server
          - systemctl start redis-server
      EOF

      # Cache servers are internal only
      create_public_ip = false

      # Cache connects to data network alongside databases
      private_networks = [
        { id = scaleway_vpc_private_network.data.id },
      ]
    }

    # --------------------------------------------------------------------------
    # Bastion/Jump Host (1 instance)
    # --------------------------------------------------------------------------
    bastion = {
      count         = 0
      instance_type = "DEV1-S"
      image         = "ubuntu_noble"

      root_volume_size_gb = 20
      root_volume_type    = "l_ssd"
      state               = "started"

      tags = ["bastion", "jump", "security"]

      cloud_init = <<-EOF
        #cloud-config
        package_update: true
        packages:
          - fail2ban
          - ufw
        runcmd:
          - ufw default deny incoming
          - ufw default allow outgoing
          - ufw allow ssh
          - ufw --force enable
          - systemctl enable fail2ban
          - systemctl start fail2ban
      EOF

      create_public_ip = true
    }

    # --------------------------------------------------------------------------
    # Worker/Job Servers (4 instances - can be stopped when not needed)
    # --------------------------------------------------------------------------
    worker = {
      count         = 0
      instance_type = "DEV1-M"
      image         = "ubuntu_noble"

      root_volume_size_gb = 40
      root_volume_type    = "l_ssd"

      # Workers can be stopped during off-hours to save costs
      state = "started"

      tags = ["worker", "jobs", "tier:processing"]

      # Additional SBS block volume for job data (created internally)
      additional_volumes = [
        { size_gb = 100, type = "sbs_5k" }, # Job data volume
      ]

      cloud_init = <<-EOF
        #cloud-config
        package_update: true
        packages:
          - docker.io
          - docker-compose
        runcmd:
          - systemctl enable docker
          - systemctl start docker
      EOF

      create_public_ip = false

      # Workers connect to data network for job processing
      private_networks = [
        { id = scaleway_vpc_private_network.data.id },
      ]
    }

    # --------------------------------------------------------------------------
    # Storage Server (demonstrates external volume attachment)
    # --------------------------------------------------------------------------
    # Note: Block volumes can only be attached to ONE instance at a time.
    # Use external_volume_ids for volumes created outside the module
    # (e.g., from snapshots, or managed by another Terraform configuration)
    storage = {
      count         = 1
      instance_type = "DEV1-S"
      image         = "ubuntu_noble"

      root_volume_size_gb = 20
      root_volume_type    = "l_ssd"
      state               = "started"

      tags = ["storage", "nfs", "tier:storage"]

      # External volume attachment (created outside the module)
      # This demonstrates attaching volumes created elsewhere
      external_volume_ids = [scaleway_block_volume.worker_external[0].id]

      cloud_init = <<-EOF
        #cloud-config
        package_update: true
        packages:
          - nfs-kernel-server
        runcmd:
          - systemctl enable nfs-server
      EOF

      create_public_ip = false

      private_networks = [
        { id = scaleway_vpc_private_network.data.id },
      ]
    }
  }

  # ============================================================================
  # SSH Key Configuration
  # ============================================================================

  create_ssh_key      = true
  ssh_public_key_file = "~/.ssh/id_ed25519.pub"

  # Alternative: provide key content directly (uncomment to use)
  # ssh_public_key = "ssh-ed25519 AAAA... user@host"

  # ============================================================================
  # Security Group Configuration
  # ============================================================================

  create_security_group = true

  # Default policies
  inbound_default_policy  = "drop"   # Deny all inbound by default
  outbound_default_policy = "accept" # Allow all outbound by default
  stateful                = true     # Track connection state

  # Inbound rules
  inbound_rules = [
    # SSH access from private network only
    {
      action   = "accept"
      protocol = "TCP"
      port     = 22
      ip_range = "10.0.0.0/8"
    },
    # HTTP/HTTPS from anywhere
    {
      action   = "accept"
      protocol = "TCP"
      port     = 80
      ip_range = "0.0.0.0/0"
    },
    {
      action   = "accept"
      protocol = "TCP"
      port     = 443
      ip_range = "0.0.0.0/0"
    },
    # API port range for backend services
    {
      action     = "accept"
      protocol   = "TCP"
      port_range = "8000-8999"
      ip_range   = "10.0.0.0/8"
    },
    # PostgreSQL from private network
    {
      action   = "accept"
      protocol = "TCP"
      port     = 5432
      ip_range = "10.0.0.0/8"
    },
    # Redis from private network
    {
      action   = "accept"
      protocol = "TCP"
      port     = 6379
      ip_range = "10.0.0.0/8"
    },
    # Health check endpoint
    {
      action   = "accept"
      protocol = "TCP"
      port     = 8080
      ip_range = "0.0.0.0/0"
    },
    # ICMP ping from private network
    {
      action   = "accept"
      protocol = "ICMP"
      ip_range = "10.0.0.0/8"
    },
  ]

  # Outbound rules (optional - outbound is allowed by default)
  outbound_rules = [
    # Allow HTTPS outbound for package updates
    {
      action   = "accept"
      protocol = "TCP"
      port     = 443
      ip_range = "0.0.0.0/0"
    },
    # Allow HTTP outbound
    {
      action   = "accept"
      protocol = "TCP"
      port     = 80
      ip_range = "0.0.0.0/0"
    },
    # Allow DNS
    {
      action   = "accept"
      protocol = "UDP"
      port     = 53
      ip_range = "0.0.0.0/0"
    },
    # Allow NTP
    {
      action   = "accept"
      protocol = "UDP"
      port     = 123
      ip_range = "0.0.0.0/0"
    },
  ]

  # ============================================================================
  # Placement Group Configuration
  # ============================================================================

  create_placement_group = true

  # Policy types:
  # - max_availability: Spread instances across different hypervisors (HA)
  # - low_latency: Place instances close together (performance)
  placement_group_policy_type = "max_availability"

  # Policy modes:
  # - optional: Best effort placement
  # - enforced: Fail if placement cannot be satisfied
  placement_group_policy_mode = "optional"

  # ============================================================================
  # Network Configuration
  # ============================================================================

  # Default private networks for all instances (supports multiple)
  private_networks = [
    { id = scaleway_vpc_private_network.main.id },
  ]

  # Public IP type: routed_ipv4, routed_ipv6, or nat
  public_ip_type = "routed_ipv4"
}
