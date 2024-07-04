variable "digitalocean_api_key" {
  description = "API key for DigitalOcean access"
  type        = string
  default     = env("DIGITALOCEAN_API_KEY")
}

variable "droplet_name" {
  description = "Name of droplet"
  type        = string
  default     = "packer-vm"
}

variable "image" {
  description = "The desired image for VM"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "region" {
  description = "Desired region"
  type        = string
  default     = "SYD1"
}

variable "size" {
  description = "Desired cpu and ram size of the droplet"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "snapshot_name" {
  description = "Snapshot name"
  type        = string
  default     = "ubuntu-nginx-std"
}

variable "snapshot_regions" {
  description = ""
  type        = list(string)
  default     = ["SYD1"]
}

variable "ssh_username" {
  description = "SSH Username"
  type        = string
  default     = "root"
}

variable "tags" {
  description = "Tags for the VM"
  type        = list(string)
  default     = ["dev", "ubuntu", "packer", "nginx"]
}
