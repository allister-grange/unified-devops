provider "digitalocean" {
  token = var.digital_ocean_api_token
}

data "digitalocean_ssh_key" "ssh_key" {
  name = var.digital_ocean_ssh_key_name
}

resource "digitalocean_droplet" "web" {
  image  = var.packer_image_id
  name   = "unified-devops-${var.env}-${formatdate("DD-MM-YY", timestamp())}"
  region = "syd1"
  size   = "s-1vcpu-1gb"
  ssh_keys = [
    data.digitalocean_ssh_key.ssh_key.id
  ]
}

resource "digitalocean_firewall" "web" {
  name = "only-22-80-and-443"

  droplet_ids = [digitalocean_droplet.web.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

}

resource "digitalocean_volume" "missinglink_db_volume" {
  region                  = "syd1"
  name                    = "missinglink-data"
  initial_filesystem_type = "ext4"
  size                    = 6
}

resource "digitalocean_volume_attachment" "missinglink_db_volume_attachment" {
  droplet_id = digitalocean_droplet.web.id
  volume_id  = digitalocean_volume.missinglink_db_volume.id

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.web.ipv4_address
    private_key = file("~/.ssh/id_rsa")
  }

  # log into the remote host and then pull down the latest db backup
  # then restore all dbs and remove the backup
  provisioner "remote-exec" {
    inline = [
      "aws s3 ls s3://unified-devops-db-backups/ --human-readable | sort | awk '{print $5}' | tail -n 1 > /tmp/latest_file.txt",
      "latest_file=$(cat /tmp/latest_file.txt)",
      "file_path=$(echo ${digitalocean_volume.missinglink_db_volume.name} | tr '-' '_' )",
      "echo $file_path/$latest_file",
      "aws s3 cp s3://unified-devops-db-backups/$latest_file /mnt/$file_path/db_backup.sql",
      "psql -f /mnt/$file_path/db_backup.sql -U postgres",
      "rm /mnt/$file_path/db_backup.sql"
    ]
  }
}
