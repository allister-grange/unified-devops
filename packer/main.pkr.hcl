packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.4"
      source  = "github.com/digitalocean/digitalocean"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }

  }
}

locals {
  timestamp = formatdate("MM-YYYY", timestamp())
}

source "digitalocean" "unbuntu_main_vm" {
  api_token     = "${var.digitalocean_api_key}"
  droplet_name  = "${var.droplet_name}-${local.timestamp}"
  image         = "${var.image}"
  region        = "${var.region}"
  size          = "${var.size}"
  ssh_username  = "${var.ssh_username}"
  snapshot_name = "${var.snapshot_name}-${local.timestamp}"
  tags          = "${var.tags}"
}

build {
  sources = ["source.digitalocean.unbuntu_main_vm"]

  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "sudo apt update",
      "sudo apt install software-properties-common -y",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y"
    ]
  }

  provisioner "ansible" {
    playbook_file = "../ansible/bootstrap.yml"
  }
}