# unified-devops

## what I want this to be

A repo that can set up all of my applications (presently, AwardIt, personal site, MissingLink, StarterTab, Umami) in the cloud, keeping in mind the concept 'cattle, not pets'

## tools and technologies

- packer
- terraform
- ansible

## how to run the scripts

```bash
# export the following environment line variables for packer secrets
export DIGITALOCEAN_API_KEY=''
export METLINK_API_KEY=''
export POSTGRES_CONNECTION_STRING=''
export ATAPIKEY1=''
export ATAPIKEY2=''
export REDIS_HOST=''
export UMAMI_DATABASE_KEY=''
export AWARDIT_DB_PASS=''
export AWARDIT_DB_HOST=''
export AWARDIT_DB_USER=''

packer init ./main.pkr.hcl

# build the packer file, pull out the packer image ID from the CLI


# deploy the packer file with terraform

```

## applications

| application                                      | frontend         | backend                      | database                  |
| ------------------------------------------------ | ---------------- | ---------------------------- | ------------------------- |
| [startertab](https://startertab.com/landingpad)  | nextjs on vercel | next js api routes on vercel | postgres on neon          |
| [awardit](https://awardit.info/)                 | react on aws s3  | ubuntu vm on digital ocean   | postgres on digital ocean |
| [missinglink](https://www.missinglink.link)      | react on vercel  | next js api routes on vercel | postgres on digital ocean |
| [personal site](https://www.allistergrange.com/) | nextjs on vercel | n/a                          | n/a                       |

## pie in the sky

- non-prod environments for all sites
- taking backups for my dbs into an s3 bucket (configured and stood up with Terraform)
- I should be able to able to bootstrap all my websites from these scripts with minimal click-ops (exceptions for things like dns)

## current baseline spending for a typical month (usd)

- $20 for Vercel
- $6 for Digital Ocean
- $2.5 for AWS

Can I get this down with containerization and free tiers? 

## what does this codebase do?

- sets up an ubuntu image using packer
- configures that image with ansible
- deploys that image, among other things using terraform

## next steps

- next action 
  - only push up the DB backups if it's PROD, don't take the backup scripts if I am doing a non-prod build
    - should be deleted out of crontab, isn't


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
  
- long term todos/clean ups
  - [ ] build a diagram to show what these scripts are doing, or just a list
  - [ ] clean up this README as a piece of documentation
  - [ ] I need to know if the database backups into s3 fail somehow, scripts?
  - [ ] hosting and deployment of the awardit front end
  - [ ] hosting and deployment of allistergrange.com front end
