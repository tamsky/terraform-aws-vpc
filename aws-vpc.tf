provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region = "${var.aws_region}"
}

resource "aws_vpc" "default" {
	cidr_block = "${var.network}.0.0/16"
	enable_dns_hostnames = "true"
	tags {
		Name = "${var.aws_vpc_name}"
	}
}

output "aws_vpc_id" {
	value = "${aws_vpc.default.id}"
}

resource "aws_internet_gateway" "default" {
	vpc_id = "${aws_vpc.default.id}"
}

output "aws_internet_gateway_id" {
	value = "${aws_internet_gateway.default.id}"
}

resource "aws_instance" "bastion" {
	ami = "${lookup(var.aws_nat_ami, var.aws_region)}"
	instance_type = "t2.small"
	key_name = "${var.aws_key_name}"
	security_groups = ["${aws_security_group.bastion.id}"]
	subnet_id = "${aws_subnet.bastion.id}"
	associate_public_ip_address = true
	source_dest_check = false
	tags {
		Name = "bastion"
	}
}

output "aws_instance_bastion_public_ip" {
       value = "${aws_instance.bastion.public_ip}"
}

resource "aws_eip" "bastion" {
	instance = "${aws_instance.bastion.id}"
	vpc = true
}

resource "aws_instance" "internal" {
	ami = "${lookup(var.aws_ubuntu_ami, var.aws_region)}"
	instance_type = "t2.small"
	key_name = "${var.aws_key_name}"
	security_groups = ["${aws_security_group.internal.id}"]
	subnet_id = "${aws_subnet.app.id}"
# only on NAT gateways:
#	associate_public_ip_address = true
#	source_dest_check = false
	tags {
		Name = "internal"
	}
}

# Public subnets

resource "aws_subnet" "bastion" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.0.0/24"
	tags {
		Name = "${var.aws_vpc_name}-bastion"
	}
}

output "bastion_subnet" {
	value = "${aws_subnet.bastion.id}"
}

output "aws_subnet_bastion_availability_zone" {
	value = "${aws_subnet.bastion.availability_zone}"
}

# Routing table for public subnets

resource "aws_route_table" "public" {
	vpc_id = "${aws_vpc.default.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.default.id}"
	}
}

output "aws_route_table_public_id" {
	value = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "bastion-public" {
	subnet_id = "${aws_subnet.bastion.id}"
	route_table_id = "${aws_route_table.public.id}"
}

# Private subnets

resource "aws_subnet" "app" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.network}.1.0/24"
	availability_zone = "${aws_subnet.bastion.availability_zone}"
	tags {
		Name = "${var.aws_vpc_name}-app"
	}
}

output "aws_subnet_app_id" {
  value = "${aws_subnet.app.id}"
}

# Routing table for private subnets

resource "aws_route_table" "private" {
	vpc_id = "${aws_vpc.default.id}"

	route {
		cidr_block = "0.0.0.0/0"
		instance_id = "${aws_instance.bastion.id}"
	}
}

output "aws_route_table_private_id" {
	value = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "app-private" {
	subnet_id = "${aws_subnet.app.id}"
	route_table_id = "${aws_route_table.private.id}"
}

##
# Security Groups
##

resource "aws_security_group" "bastion" {
	name = "bastion"
	description = "Allow SSH traffic, and tcp/NAT from the internet"
	vpc_id = "${aws_vpc.default.id}"

	ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }

	ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        self = true
        security_groups = [ "${aws_security_group.internal.id}" ]
        }

	egress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }

	tags {
		Name = "${var.aws_vpc_name}-bastion"
	}

}

resource "aws_security_group" "internal" {
	name = "internal"
	description = "Allow traffic within our VPC subnet"
	vpc_id = "${aws_vpc.default.id}"

	ingress {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_blocks = [ "${aws_vpc.default.cidr_block}" ]
        }

        egress {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_blocks = [ "${aws_vpc.default.cidr_block}" ]
        }

	tags {
		Name = "${var.aws_vpc_name}-internal"
	}

}

output "aws_security_group_bastion_id" {
  value = "${aws_security_group.bastion.id}"
}

output "aws_security_group_internal_id" {
  value = "${aws_security_group.internal.id}"
}
