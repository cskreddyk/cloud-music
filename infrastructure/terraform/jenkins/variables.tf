variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "project_name" {
  type    = string
  default = "cloudmusic"
}

variable "ami_id" {
  type    = string
  default = "ami-0146cfc901859a3e4"
}

variable "instance_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "root_volume_size" {
  type    = number
  default = 50
}

variable "state_bucket" {
  type    = string
  default = "cloudmusic-tfstate-611708420769-ap-northeast-1"
}
