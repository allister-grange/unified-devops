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

  // removes `debconf: unable to initialize frontend: Dialog` error
  provisioner "shell" {
    inline = [
      "echo set debconf to Noninteractive", 
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections" ]
  }

  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "sudo apt update -o DPkg::Lock::Timeout=-1 -y",
      "sudo add-apt-repository -y --update ppa:ansible/ansible",
      "sudo apt install ansible -y"
    ]
  }

  provisioner "ansible" {
    playbook_file = "../ansible/bootstrap.yml"
    user = "root"
    use_proxy = false
  }
}