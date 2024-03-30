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

data "digitalocean_ssh_key" "ssh_key" {
  name = var.digital_ocean_ssh_key_name
}

resource "digitalocean_droplet" "web" {
  image  = var.packer_image_id
  name   = "unified-devops-${formatdate("DD-MM-YY", timestamp())}"
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
  name                    = "volume-missinglink-db-non-prod"
  initial_filesystem_type = "ext4"
  size                    = 6
}

resource "digitalocean_volume_attachment" "missinglink_db_volume_attachment" {
  droplet_id = digitalocean_droplet.web.id
  volume_id  = digitalocean_volume.missinglink_db_volume.id
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
      days = 7
    }
  }
}