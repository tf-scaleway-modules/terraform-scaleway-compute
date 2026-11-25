terraform {
  required_version = ">= 1.11.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.93"
    }
  }
}

provider "scaleway" {
  zone   = "fr-par-1"
  region = "fr-par"
}
