provider "aws" {
  region = "ap-southeast-2"
}

variable "missinglink_domain" {
  description = "domain for the missinglink backend"
  default     = "qa.backend.missinglink.link"
}

variable "awardit_domain" {
  description = "domain for the awardit backend"
  default     = "qa.backend.awardit.info"
}

variable "umami_domain" {
  description = "domain for the umami"
  default     = "qa.umami.startertab.com"
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
  zone_id    = aws_route53_zone.missinglink_zone.zone_id
  name       = var.missinglink_domain
  type       = "A"
  ttl        = "300"
  records    = ["${digitalocean_droplet.web.ipv4_address}"]
  depends_on = [digitalocean_droplet.web]

}

# AwardIt backend zone
resource "aws_route53_zone" "awardit_zone" {
  name = "awardit.info"
}

resource "aws_route53_record" "awardit_backend_record" {
  zone_id    = aws_route53_zone.awardit_zone.zone_id
  name       = var.awardit_domain
  type       = "A"
  ttl        = "300"
  records    = ["${digitalocean_droplet.web.ipv4_address}"]
  depends_on = [digitalocean_droplet.web]
}

# StarterTab zone
resource "aws_route53_zone" "startertab_zone" {
  name = "startertab.com"
}

resource "aws_route53_record" "umami_record" {
  zone_id    = aws_route53_zone.startertab_zone.zone_id
  name       = var.umami_domain
  type       = "A"
  ttl        = "300"
  records    = ["${digitalocean_droplet.web.ipv4_address}"]
  depends_on = [digitalocean_droplet.web]
}
