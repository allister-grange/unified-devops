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
  - [ ] s3 bucket backups for the databases (something I need to get going on the extant VM)
    - [ ] procure an s3 api key
    - [ ] use terraform to build an s3 bucket
    - [ ] get a script working that takes a postgres backup to a directory
    - [ ] use a cron job to push that up to s3
    - [ ] include those scripts (to pull down once), and then to push up in the future in ansibleow to 
  - [ ] postgres setup
    - [ ] install the db
    - [ ] accounts
    - [ ] databases (comes from s3, have a command line or variable to disable this so that it doesn't use too much bandwidth)
- [ ] how do I do DNS to set this up as a non-prod? 

- use terraform for the following
  - [X] standing up the image
  - [X] get the IP showing after creation 
  - [X] nbfw create a new rule and attach it
  - [ ] test the ssh to the host with those locked down ips
  - [ ] edit aws route53 to point the non-prod dns entry to the host's IP using provisioners
    - [ ] gonna need an amazon API key...
  - [X] certificates (letsencrypt)
    - [ ] generate letsencrypt certs (sudo certbot --nginx)


- long term todos/clean ups
  - [ ] nginx configs should be split into 3 services


In its current state, I would need to manually point the Route 53 dns records to the new host, and then run `sudo certbot --nginx`, then it should be good to go. I can automate this using provisioners on the Terraform side of things. I should set up the databases before this. 