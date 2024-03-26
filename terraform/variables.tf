variable "digital_ocean_api_token" {
  default = "use command line arguments to pass me in"
}

variable "digital_ocean_ssh_key_name" {
  description = "This is the ssh key that is stored within DigitalOcean Settings"
  default = "packer"
}

variable "packer_image_id" {
  description = "Id of the image that Packer generates, you have to grab this off the command line for now"
  default = "use command line arguments to pass me in"
}