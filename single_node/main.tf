locals {
    current_timestamp  = timestamp()
    current_timestamp_str = formatdate("YYYYMMDDhhmmss", local.current_timestamp)
}

provider "aws" {
  region  = "${var.aws_region}"
}

data "aws_availability_zone" "ami_builder_az" {
  name = "${var.aws_az}"
}



resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_key_pair" "aws_keypair" {
  key_name   = "xrv9k_aws_amibuilder_${local.current_timestamp_str}"
  public_key = "${file(var.ssh_key_public)}"
}

resource "aws_security_group" "server_sg" {
  vpc_id = "${aws_default_vpc.default.id}"

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
  ami           = "${var.aws_ami_xrv9k[var.xr_version]}"
  instance_type = "${var.xrv9k_instance_type[var.xr_version]}"
  key_name      = "${aws_key_pair.aws_keypair.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.server_sg.id}"]
  associate_public_ip_address = true

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
