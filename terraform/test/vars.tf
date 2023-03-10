variable "ami" {
  type    = list(string)
  default = [ "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" ]
}

variable "instance_name" {
  type    = string
}

variable "instance_count" {
  type    = number
  default = 3
}

variable "instance_tags" {
  type    = list(string)
}

variable "instance_type" {
  type    = string
  default = "t3a.xlarge"
}

variable "volume_size" {
  type    = number
  default = 256
}

variable "volume_type" {
  type    = string
  default = "gp3"
}

variable "cidr_blocks" {
  type    = list(string)
  default = [ "192.168.0.0/16", "0.0.0.0/0" ]
}
