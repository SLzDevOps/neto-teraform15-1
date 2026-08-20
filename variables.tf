variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "zone" {
  description = "Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet"
  type        = string
  default     = "192.168.10.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for private subnet"
  type        = string
  default     = "192.168.20.0/24"
}

variable "nat_instance_image_id" {
  description = "Image ID for NAT instance"
  type        = string
  default     = "fd80mrhj8fl2oe87o4e1"
}

variable "vm_image_family" {
  description = "Family name of the image to use for VMs"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "ssh_public_key" {
  description = "Path to your public SSH key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
