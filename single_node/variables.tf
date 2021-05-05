variable "xr_version" {
  default = "732_ena"
}

variable "ssh_key_public" {
  default     = "./ssh/id_rsa.pub"
  description = "Path to the SSH public key for accessing cloud instances. Used for creating AWS keypair."
}

variable "ssh_key_private" {
  default     = "./ssh/id_rsa"
  description = "Path to the SSH public key for accessing cloud instances. Used for creating AWS keypair."
}

variable "aws_region" {
  default = "us-west-2"
}

variable "aws_az" {
  default = "us-west-2a"
}

variable "xrv9k_instance_type" {
  type = map(string)

  default = {
      "631" =  "m4.xlarge"
      "732_ena" = "c5n.4xlarge"
  }
}


variable "aws_ami_xrv9k" {
  type = map(string)

  default = {
    "631"     = "ami-894392f1"
    "732_ena" = "ami-0ca65648b4429aafe"
  }
}
