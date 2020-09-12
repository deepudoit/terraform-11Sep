variable "namespace" {
  description = "Project namespace for unique resource mapping"
  type = string
}

variable "ssh_key" {
  description = "SSH key for Ec2 instance"
  type = string
  default = null
}

variable "region" {
  description = "AWS region"
  default = "us-east-1"
  type = string
}