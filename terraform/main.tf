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
}

provider "digitalocean" {
  token = var.digital_ocean_api_token
}

provider "aws" {
  region = "ap-southeast-2"
}

variable "missinglink_domain" {
  description = "domain for the missinglink backend"
  default = "qa.backend.missinglink.link"
}

variable "awardit_domain" {
  description = "domain for the awardit backend"
  default = "qa.backend.awardit.info"
}

variable "env" {
  description = "env that is being run, by default it's dev"
  default = "dev"
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

resource "aws_s3_bucket" "s3_bucket_db_backups" {
  bucket = "unified-devops-db-backups"
}

resource "aws_s3_bucket_policy" "s3_bucket_policy_db_backups" {
  bucket = aws_s3_bucket.s3_bucket_db_backups.id
  policy = <<EOT
  {
    "Version": "2012-10-17",
    "Id": "PublicAccessPolicy",
    "Statement": [
        {
            "Sid": "PublicReadWrite",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
              "${aws_s3_bucket.s3_bucket_db_backups.arn}",
              "${aws_s3_bucket.s3_bucket_db_backups.arn}/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalAccount": "299739285952"
                }
            }
        }
    ]
  }
  EOT
}

resource "aws_s3_bucket_lifecycle_configuration" "aws_s3_bucket_lifecycle_db_backups" {
  bucket = aws_s3_bucket.s3_bucket_db_backups.id

  rule {
    id     = "delete_old_backups"
    status = "Enabled"
    expiration {
      days = 3
    }
  }
}

# MissingLink backend zone
resource "aws_route53_zone" "missinglink_zone" {
  name = "missinglink.link"
}

resource "aws_route53_record" "missinglink_backend_record" {
  zone_id = aws_route53_zone.missinglink_zone.zone_id
  name    = var.missinglink_domain
  type    = "A"
  ttl     = "300"
  records = ["${digitalocean_droplet.web.ipv4_address}"]
  depends_on = [ digitalocean_droplet.web ]

}

# AwardIt backend zone
resource "aws_route53_zone" "awardit_zone" {
  name = "awardit.info"
}

resource "aws_route53_record" "awardit_backend_record" {
  zone_id = aws_route53_zone.awardit_zone.zone_id
  name    = var.awardit_domain
  type    = "A"
  ttl     = "300"
  records = ["${digitalocean_droplet.web.ipv4_address}"]
  depends_on = [ digitalocean_droplet.web ]
}

# I only want to trigger this whenever the digital ocean droplet is re-built
resource "null_resource" "install_certs" {
  triggers = {
    key = "${ digitalocean_droplet.web.id }"
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.web.ipv4_address
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo certbot --nginx --non-interactive --agree-tos -m allistergrange@gmail.com --domains ${var.missinglink_domain},${var.awardit_domain}",
    ]
  }

  depends_on = [ aws_route53_record.awardit_backend_record, aws_route53_record.missinglink_backend_record ]
}

resource "null_resource" "turn_on_h2" {
  triggers = {
    key = "${ digitalocean_droplet.web.id }"
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

  depends_on = [ null_resource.install_certs ]
}

resource "null_resource" "populate_db_with_latest_data" {
  triggers = {
    key = "${ digitalocean_droplet.web.id }"
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.web.ipv4_address
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "bash /home/deployer/missinglink-updates.sh"
    ]
  }

  depends_on = [ digitalocean_volume_attachment.missinglink_db_volume_attachment ]
}
