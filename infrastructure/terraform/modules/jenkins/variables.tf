variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "root_volume_size" {
  type    = number
  default = 50
}

variable "ecr_repository_arns" {
  type = list(string)
}
