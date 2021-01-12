# provider "aws" {
#     profile = "default"
#     region = "us-east-1"
# }

variable "name" {
  default = "terraform-kubernetes"
}

# variable "public_key_path" {
#   description = <<DESCRIPTION
# Path to the SSH public key to be used for authentication.
# Ensure this keypair is added to your local SSH agent so provisioners can
# connect.

# Example: ~/.ssh/terraform.pub
# DESCRIPTION
# }

variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "172.16.0.0/16"
}

variable "az" {
  default = "us-east-1b"
}

variable "instance_type" {
  default = "t3.small"
}

variable "master" {
  default = [
    "k8s-master-1",
    "k8s-master-2",
    "k8s-master-3"
  ]
}

variable "worker" {
  default = [
    "k8s-worker-1",
    "k8s-worker-2",
    "k8s-worker-3"
  ]
}

variable "ec2_config" "k8s-master-1" {
  type = "map"
  default = {
    ami = "ami-09582a9089ec391ca"
    instance_type = "t3.small" 
    instance_key = "id_rsa" 
  }
}