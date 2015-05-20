variable "vpc_name" {
  default=""
  description="the name of the vpc"
}

variable "cidr_prefix" {
  default="10.10"
  description="VPC subnet prefix; NN.MM portion of NN.MM.0.0/16"
}

variable "prefix" {
  default=""
  description="prefix appended to all objects"
}

resource "aws_vpc" "default" {
	cidr_block = "${var.cidr_prefix}.0.0/16"
	enable_dns_hostnames = "true"
	tags {
		Name = "${var.prefix}${var.vpc_name}"
	}
}

output "id" {
	value = "${aws_vpc.default.id}"
}

output "cidr_block" {
       value = "${aws_vpc.default.cidr_block}"
}

output "aws_vpc_name" {
	value = "${aws_vpc.default.tags.Name}"
}
