# ==============================================================================
# Complete Example - Multiple Instance Groups
# ==============================================================================

module "compute" {
  source = "../../"

  organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  project_name    = "ecommerce"
  zone            = "fr-par-1"

  tags = ["production", "ecommerce"]

  # Multiple instance groups with different configurations
  instances = {
    # 3 backend servers
    backend = {
      count               = 3
      instance_type       = "GP1-S"
      image               = "ubuntu_noble"
      root_volume_size_gb = 50
      tags                = ["backend", "api"]

      cloud_init = <<-EOF
        #cloud-config
        packages: [docker.io]
        runcmd:
          - systemctl enable docker
          - systemctl start docker
      EOF
    }

    # 4 frontend servers
    frontend = {
      count               = 4
      instance_type       = "DEV1-M"
      image               = "ubuntu_noble"
      root_volume_size_gb = 30
      tags                = ["frontend", "web"]

      cloud_init = <<-EOF
        #cloud-config
        packages: [nginx]
        runcmd:
          - systemctl enable nginx
          - systemctl start nginx
      EOF
    }

    # 1 database server with additional volume
    database = {
      count               = 1
      instance_type       = "GP1-M"
      image               = "ubuntu_noble"
      root_volume_size_gb = 50
      tags                = ["database", "postgres"]

      additional_volumes = [
        { size_gb = 200, type = "b_ssd" }
      ]

      enable_backup_snapshot = true

      cloud_init = <<-EOF
        #cloud-config
        packages: [postgresql]
      EOF
    }
  }

  # SSH key
  create_ssh_key      = true
  ssh_public_key_file = "~/.ssh/id_rsa.pub"

  # Security rules
  inbound_rules = [
    { protocol = "TCP", port = 22, ip_range = "10.0.0.0/8" },
    { protocol = "TCP", port = 80 },
    { protocol = "TCP", port = 443 },
  ]

  # Placement group
  create_placement_group      = true
  placement_group_policy_type = "max_availability"
}
