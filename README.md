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

- next action 
  - [ ] test umami installation
    - [ ] 502 bad gateway on the frontned 
    - [ ] the node packages take wayyy to long to download / install - can I speed this up?
  - [ ] I want all non-prod/prod distinctions to be made in Terraform, not ansible. Ansible is to set up a common image with packer. This image is then shared across the environments with light tuning. 
    - [ ] go through all of ansible and determine if I need anything turned off in non-prod
      - [ ] only push up the DB backups if it's PROD, don't take the backup scripts if I am doing a non-prod build
        - [ ] should I just disable this with a remote-exec in terraform?
  - [ ] store terraform state in an s3 bucket

- move from Vercel to Cloudflare pages for startertab
  - [ ] get a baseline of speed for comparison
  - [ ] build out a non-prod env using terraform in Cloudflare pages
  - [ ] swap out prod
  - [ ] [Cloudflare link](https://developers.cloudflare.com/pages/framework-guides/nextjs/deploy-a-nextjs-site/)
  - [ ] [Terraform link](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/pages_project)

- use ansible to set up my ubuntu image with the following
  - [X] firewall rules
    - [X] hbfw (ssh and https, nothing else)
  - [X] nginx
  - [X] nodejs and .net installs
  - [X] redis
  - [X] configuring the swap (common)
  - [X] systemd for missinglink & awardit
  - [X] cron job to call the missinglink backend
  - [X] s3 bucket backups for the databases (something I need to get going on the extant VM)
    - [X] procure an s3 api key
    - [X] use terraform to build an s3 bucket
    - [X] get a script working that takes a postgres backup to a directory
      - [X] need to create a new disk volume, running out of space (20gb) (needs 5gb then more for backing up...)
    - [X] use a cron job to back up and push up the backup to s3 daily
    - [X] include those scripts (to pull down once), and then to push up in the future 
  - [X] postgres setup
    - [X] install the db
    - [X] accounts
    - [X] edit the PostgreSQL pg_hba.conf file so that it allows logins from localhost so I can take backups [answer](https://chat.openai.com/c/b51fb1c3-42ad-4ec0-ae07-6b261d9d01e3)
    - [X] databases (comes from s3, have a command line or variable to disable this so that it doesn't use too much bandwidth)
- [X] how do I do DNS to set this up as a non-prod? 

- use terraform for the following
  - [X] standing up the image
  - [X] get the IP showing after creation 
  - [X] nbfw create a new rule and attach it
  - [X] edit aws route53 to point the non-prod dns entry to the host's IP using provisioners
  - [X] certificates (letsencrypt)
    - [X] generate letsencrypt certs (sudo certbot --nginx)
  - [X] set up nginx for non-prod
  - [X] set up dns records for non-prod using route 53
  - [X] set up certificates
  
  - get this all working with non-prod front ends
    - [ ] set up startertab with cloudflare?
    - [ ] how do I manage the non-prods envs linking in with Vercel, I need to get my backend urls from env variables


- long term todos/clean ups
  - [ ] breakdown terraform files into aws and digital ocean
  - [ ] build a diagram to show what these scripts are doing, or just a list
  - [ ] go through and tidy up all hardcoded paths
  - [ ] nginx configs should be split into 3 services
  - [ ] can I merge group_vars and the vars folders?
  - [ ] I need to know if the database backups into s3 fail somehow, scripts?
  - [ ] separate out prod/non-prod builds
    - [ ] only push up the DB backups if it's PROD, don't take the backup scripts if I am doing a non-prod build
    - [ ] domain names should be sorted by prod/non-prod
  - [ ] move all install paths to /opt/ (find best practise using LLM tools)
  - [ ] go through and put variables in for all paths etc in ansible
  - [ ] review all nginx confs, best practise?