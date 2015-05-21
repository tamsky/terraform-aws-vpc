variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {}
variable "aws_region" {
  default = "us-west-2"
}

variable "env_count" {
  default = 1
}

variable "aws_vpc_network" {
  default = "10.10"
  description="VPC subnet prefix; NN.MM portion of NN.MM.0.0/16"
}

variable "aws_vpc_name" {
  default = "vpc"
}

variable "aws_ubuntu_ami" {
    default = {
        us-east-1 = "ami-98aa1cf0"
        us-west-1 = "ami-736e6536"
        us-west-2 = "ami-3389b803"
        ap-northeast-1 = "ami-df4b60de"
        ap-southeast-1 = "ami-2ce7c07e"
        ap-southeast-2 = "ami-1f117325"
        eu-west-1 = "ami-f6b11181"
        sa-east-1 = "ami-71d2676c"
    }
}

variable "aws_centos_ami" {
    default = {
        us-east-1 = "ami-00a11e68"
        us-west-1 = "ami-e04b7aa5"
        us-west-2 = "ami-3425be04"
        ap-northeast-1 = "ami-9392dc92"
        ap-southeast-1 = "ami-dcbeed8e"
        ap-southeast-2 = "ami-89e88db3"
        eu-west-1 = "ami-af6faad8"
        sa-east-1 = "ami-73ee416e"
    }
}

variable "aws_nat_ami" {
    default = {
        us-east-1 = "ami-4c9e4b24"
        us-west-1 = "ami-1d2b2958"
        us-west-2 = "ami-75ae8245"
        ap-northeast-1 = "ami-49c29e48"
        ap-southeast-1 = "ami-d482da86"
        ap-southeast-2 = "ami-a164029b"
        eu-west-1 = "ami-5b60b02c"
        sa-east-1 = "ami-8b72db96"
    }
}

variable "prefix" {}
