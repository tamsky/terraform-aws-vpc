provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region = "${var.aws_region}"
}

module "aws-vpc" {
  source = "./aws_vpc"
  cidr_prefix="${var.aws_vpc_network}"
  prefix = "${var.prefix}"
  vpc_name = "${var.aws_vpc_name}"
}

resource "aws_internet_gateway" "default" {
	vpc_id = "${module.aws-vpc.id}"
}

output "aws_internet_gateway_id" {
	value = "${aws_internet_gateway.default.id}"
}

##
# jump / bastion host
##
resource "aws_instance" "jump" {
	ami = "${lookup(var.aws_ubuntu_ami, var.aws_region)}"
	instance_type = "t2.small"
	key_name = "${var.aws_key_name}"
	security_groups = ["${aws_security_group.straddle.id}"]
	subnet_id = "${aws_subnet.public.id}"
	associate_public_ip_address = true
	source_dest_check = true  # this host is NOT a NAT gateway
	tags {
		Name = "jump"
	}
}

output "aws_instance_jump_public_ip" {
       value = "${aws_instance.jump.public_ip}"
}

resource "aws_eip" "jump" {
	instance = "${aws_instance.jump.id}"
	vpc = true
}

##
# NAT gateway
##

resource "aws_instance" "nat" {
	ami = "${lookup(var.aws_nat_ami, var.aws_region)}"
	instance_type = "t2.small"
	key_name = "${var.aws_key_name}"
	security_groups = ["${aws_security_group.straddle.id}"]
	subnet_id = "${aws_subnet.public.id}"
	associate_public_ip_address = true

        # as a NAT box, we will receive default routed traffic, disable check:
	source_dest_check = false  

	tags {
		Name = "nat"
	}
}

output "aws_instance_nat_public_ip" {
       value = "${aws_instance.nat.public_ip}"
}

resource "aws_eip" "nat" {
	instance = "${aws_instance.nat.id}"
	vpc = true
}


##
# INTERNAL sample host
##

resource "aws_instance" "internal" {
	ami = "${lookup(var.aws_ubuntu_ami, var.aws_region)}"
	instance_type = "t2.small"
	key_name = "${var.aws_key_name}"
	security_groups = ["${aws_security_group.private.id}"]
	subnet_id = "${aws_subnet.app.id}"
	associate_public_ip_address = false
	source_dest_check = true
	tags {
		Name = "internal"
	}
}

# Public subnets

resource "aws_subnet" "public" {
	vpc_id = "${module.aws-vpc.id}"
	cidr_block = "${var.aws_vpc_network}.0.0/24"
	tags {
		Name = "${var.aws_vpc_name}-public"
	}
}

output "public_subnet" {
	value = "${aws_subnet.public.id}"
}

output "aws_subnet_public_availability_zone" {
	value = "${aws_subnet.public.availability_zone}"
}

# Routing table for public subnets

resource "aws_route_table" "public" {
	vpc_id = "${module.aws-vpc.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.default.id}"
	}
        tags {
             Name = "public route table"
        }
}

output "aws_route_table_public_id" {
	value = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public" {
	subnet_id = "${aws_subnet.public.id}"
	route_table_id = "${aws_route_table.public.id}"
}

# Private subnets

resource "aws_subnet" "app" {
	vpc_id = "${module.aws-vpc.id}"
	cidr_block = "${var.aws_vpc_network}.1.0/24"
	availability_zone = "${aws_subnet.public.availability_zone}"
	tags {
		Name = "${var.aws_vpc_name}-app"
	}
}

output "aws_subnet_app_id" {
  value = "${aws_subnet.app.id}"
}

# Routing table for private subnets

resource "aws_route_table" "private" {
	vpc_id = "${module.aws-vpc.id}"

	route {
		cidr_block = "0.0.0.0/0"
		instance_id = "${aws_instance.nat.id}"
	}
        tags {
             Name = "private route table - default route to NAT gateway"
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

resource "aws_security_group" "straddle" {
	name = "straddle"
	description = "Allow public ssh, tcp/NAT to/from internet, and internal subnet"
	vpc_id = "${module.aws-vpc.id}"

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
        security_groups = [ "${aws_security_group.private.id}" ]
        }

        # need this to be able to NAT out:
	egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        }

	tags {
		Name = "${var.aws_vpc_name}-public"
	}

}

resource "aws_security_group" "private" {
	name = "private"
	description = "Allow traffic within our VPC subnet"
	vpc_id = "${module.aws-vpc.id}"

	ingress {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_blocks = [ "${module.aws-vpc.cidr_block}" ]
        }

        egress {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_blocks = [ "0.0.0.0/0" ]
        }

	tags {
		Name = "${var.aws_vpc_name}-internal"
	}

}

output "aws_security_group_straddle_id" {
  value = "${aws_security_group.straddle.id}"
}

output "aws_security_group_private_id" {
  value = "${aws_security_group.private.id}"
}
