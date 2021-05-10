locals {
    current_timestamp  = timestamp()
    current_timestamp_str = formatdate("YYYYMMDDhhmmss", local.current_timestamp)

    # Set up GW IP for mgmt subnet - to be used in default route config for xrv9k
    mgmt_gw_ip = cidrhost(var.vpc_mgmt_subnet_cidr, 1)
    
    # Set up Mgmt IP for xrv9k TenGig0/0/0/0 (first interface)
    mgmt_ip = cidrhost(var.vpc_mgmt_subnet_cidr, var.xrv9k_mgmt_subnet_hostnum)

    # Set up Mgmt netmask for xrv9k TenGig0/0/0/0 (first interface)
    mgmt_subnet = element(split("/", var.vpc_mgmt_subnet_cidr), 1)
}

provider "aws" {
  region  = "${var.aws_region}"
}

data "aws_availability_zone" "xrv9k_az" {
  name = "${var.aws_az}"
}


resource "aws_vpc" "vpc" {
  cidr_block = "${var.aws_vpc_cidr}"

  tags = {
    Name = "terraform_xrv9k_vpc"
  }
}

resource "aws_internet_gateway" "terraform_gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "Internet gateway for xrv9k"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.terraform_gw.id}"
  }

  tags = {
    Name = "xrv9k route table"
  }
}


resource "aws_subnet" "mgmt_subnet" {
  vpc_id     = "${aws_vpc.vpc.id}"
  availability_zone = "${data.aws_availability_zone.xrv9k_az.name}"
  cidr_block = "${var.vpc_mgmt_subnet_cidr}"

  # map_public_ip_on_launch = true
  tags = {
    Name = "xrv9k Mgmt Subnet"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.mgmt_subnet.id}"
  route_table_id = "${aws_route_table.route_table.id}"
}


resource "aws_key_pair" "aws_keypair" {
  key_name   = "xrv9k_aws_${local.current_timestamp_str}"
  public_key = "${file(var.ssh_key_public)}"
}

resource "aws_security_group" "server_sg" {
  vpc_id = "${aws_vpc.vpc.id}"

  # SSH ingress access for provisioning
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access for provisioning"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "xrv9k" {
  ami                         = "${var.aws_ami_xrv9k[var.xr_version]}"
  instance_type               = "${var.xrv9k_instance_type[var.xr_version]}"
  key_name                    = "${aws_key_pair.aws_keypair.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.server_sg.id}"]
  associate_public_ip_address = true
  subnet_id                   = "${aws_subnet.mgmt_subnet.id}"
  private_ip                  = "${local.mgmt_ip}"
  user_data = templatefile("${path.module}/user-data/config.tpl", { hostname = var.xrv9k_hostname, mgmt_ip = local.mgmt_ip, mgmt_subnet = local.mgmt_subnet,  mgmt_gw_ip =local.mgmt_gw_ip})


  tags = {
    Name = "xrv9k_terraform_${var.xr_version}"
  }

  root_block_device  {
      delete_on_termination = true
      volume_type = "gp2"
  }
}

resource "null_resource" "deployment" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "remote-exec" {
    inline = ["show version"]
    on_failure = continue
    connection {
      timeout     = "35m"
      host        = "${aws_instance.xrv9k.public_ip}"
      type        = "ssh"
      user        = "root"
      private_key = "${file(var.ssh_key_private)}"
    }
  }

}
