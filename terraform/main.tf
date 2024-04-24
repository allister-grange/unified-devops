terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "unified-devops-terraform-state"
    key    = "terraform.tfstate"
    region = "ap-southeast-2"
  }
}

variable "env" {
  description = "env that is being run, by default it's dev"
  default     = "dev"
}

# I only want to trigger this whenever the digital ocean droplet is re-built
resource "null_resource" "install_certs" {
  triggers = {
    key = "${digitalocean_droplet.web.id}"
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.web.ipv4_address
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo certbot --nginx --non-interactive --agree-tos -m allistergrange@gmail.com --domains ${var.missinglink_domain},${var.awardit_domain},${var.umami_domain}",
    ]
  }

  depends_on = [aws_route53_record.awardit_backend_record, aws_route53_record.missinglink_backend_record]
}

resource "null_resource" "turn_on_h2" {
  triggers = {
    key = "${digitalocean_droplet.web.id}"
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.web.ipv4_address
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i \"s/listen 443 ssl;/listen 443 ssl http2;/g\" /etc/nginx/nginx.conf && service nginx restart",
    ]
  }

  depends_on = [null_resource.install_certs]
}

resource "null_resource" "populate_db_with_latest_data" {
  triggers = {
    key = "${digitalocean_droplet.web.id}"
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.web.ipv4_address
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "bash /srv/www/missinglink/missinglink-updates.sh"
    ]
  }

  depends_on = [digitalocean_volume_attachment.missinglink_db_volume_attachment]
}

# must be done on the deploy stage as umami needs a live db connection to build
resource "null_resource" "build_and_start_up_umami" {
  triggers = {
    key = "${digitalocean_droplet.web.id}"
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.web.ipv4_address
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "cd /srv/www/umami",
      "export NODE_OPTIONS=--max-old-space-size=512",
      "yarn build",
      "pm2 start npm --name umami -- start",
      "pm2 startup",
      "pm2 save"
    ]
  }

  depends_on = [digitalocean_volume_attachment.missinglink_db_volume_attachment]
}

# remove the backup job for the database if the env isn't prod
resource "null_resource" "disable_db_backups" {
  triggers = {
    key = "${digitalocean_droplet.web.id}"
  }

  count = var.env != "prod" ? 1 : 0

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.web.ipv4_address
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "crontab -l | grep -v 'home/deployer/backup_db.sh' | crontab -"
    ]
  }

  depends_on = [digitalocean_droplet.web]
}
