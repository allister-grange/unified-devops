# unified-devops

## what I want this to be

A repo that can set up all of my applications (presently, AwardIt, personal site, MissingLink, StarterTab, Umami) in the cloud, keeping in mind the concept 'cattle, not pets'

## tools and technologies

- kubernetes
- packer
- terraform

## pie in the sky

- non-prod environments for all sites
- taking backups for my dbs into an s3 bucket (configured and stood up with Terraform)
- I should be able to able to bootstrap all my websites from these scripts with minimal click-ops (exceptions for things like dns)

## current baseline spending for a typical month (usd)

- $20 for Vercel
- $6 for Digital Ocean
- $2.5 for AWS

Can I get this down with containerization and free tiers? 

## next steps

- use ansible to set up my ubuntu image with the following
  - nginx
  - systemd for missinglink & awardit
  - cron job to call the missinglink backend
  - postgres setup
  - certificates (letsencrypt)
  - firewall rules (hbfw and nbfw)
  - nodejs and .net installs
  - configuring the swap
  - s3 bucket backups for the db