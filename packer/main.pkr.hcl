packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.4"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

locals {
  timestamp = formatdate("MM-YYYY", timestamp())
}

source "digitalocean" "unbuntu_main_vm" {
  api_token       = "${var.digitalocean_api_key}"
  droplet_name    = "${var.droplet_name}-${local.timestamp}"
  image           = "${var.image}"
  region          = "${var.region}"
  size            = "${var.size}"
  ssh_username    = "${var.ssh_username}"
  snapshot_name   = "${var.snapshot_name}-${local.timestamp}"
  tags            = "${var.tags}"
}

build {
  // define what sources you want to build
  sources = ["source.digitalocean.unbuntu_main_vm"]
  
  provisioner "shell" {
    script = "./scripts/bootstrap.sh"
  }

  provisioner "ansible" {
      playbook_file = "../ansible/playbook.yml"
  }
}