# xrv9k-aws-topo

Want to build your own AWS compatible AMI image for xrv9k ? Take a look here:  <https://github.com/akshshar/xrv9k-amibuilder>

Terraform makes it super easy to spin up simple and complex network topologies on AWS with xrv9k instances.


## Requirements: Setting up the Client Machine (Laptop/Server)

### Set up Routing to AWS

The client machine may be your laptop or any server/machine thas has internet access capable of reaching AWS public ip addresses.
You can view the block of public IP addresses that AWS uses by navigating here:  <https://ip-ranges.amazonaws.com/ip-ranges.json> and setting up routing appropriately.


### Compatible OS

Technically the entire spin-up process runs using docker containers and nothing needs to be installed on the client machine except for docker itself. Since docker is supported on Linux, MacOSX and Windows, you should be able to run the build code on any of these operating systems once docker is up and running.

### Install Docker Engine

Navigate here: <https://docs.docker.com/engine/install/> to install Docker Engine for the OS running on your selected Client Machine. The instructions below capture the build flow from MacOSX.


### Fetch your AWS Credentials
You will need to set up your AWS credentials before running the code. So fetch your Access Key and Secret Key as described here for programmatic access to AWS APIs:
<https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys>  
and keep them ready.




## Working with xrv9k-aws-topo

### Clone the git repo

```
aks::~$git clone https://github.com/akshshar/xrv9k-aws-topo
Cloning into 'xrv9k-aws-topo'...
remote: Enumerating objects: 19, done.
remote: Counting objects: 100% (19/19), done.
remote: Compressing objects: 100% (14/14), done.
remote: Total 19 (delta 2), reused 19 (delta 2), pack-reused 0
Unpacking objects: 100% (19/19), done.
aks::~$
aks::~$cd xrv9k-aws-topo
aks::~/xrv9k-aws-topo$
aks::~/xrv9k-aws-topo$tree .
.
├── README.md
└── single_node
    ├── aws
    │   └── credentials
    ├── main.tf
    ├── ssh
    │   └── PlaceSSHKeysHere.md
    ├── ssh_config
    ├── variables.tf
    ├── xrv9k_bringdown
    └── xrv9k_bringup

3 directories, 8 files
aks::~/xrv9k-aws-topo$
```


### Set up the AWS credentials

As explained in the requirements section, once you have the Access Key and Secret Key associated with your account ready, fill out `aws/credentials` file in the git repo:

```
aks::~/xrv9k-amibuilder$  cat aws/credentials 
[default]
aws_access_key_id =
aws_secret_access_key =

```

### Copy rsa key pair of your Client Machine to ssh/

Generate an RSA key pair:
private-key filename:  id_rsa 
public-key filename: id_rsa.pub

Follow the instructions relevant to the OS of your client machine to do so.
Then copy the key files over to the `ssh/` directory of the cloned git repo:

```
aks::~/xrv9k-amibuilder$cp ~/.ssh/id_rsa* ssh/
aks::~/xrv9k-amibuilder$
aks::~/xrv9k-amibuilder$tree ./ssh
./ssh
├── PlaceSSHKeysHere.md
├── id_rsa
└── id_rsa.pub

0 directories, 3 files
aks::~/xrv9k-amibuilder$
```

### Topology Specific Directories

In the git repo you will find topology-specific directories that will be populated over time. The most basic topology is a single xrv9000 instance that is spun up inside an AWS VPC with a public ip address allowing access over SSH through appropriate firewall rules. You will find this basic topology specified using the variables.tf and main.tf terraform files in the `single_node/` directory.


### View the variables.tf and main.tf files

These files describe the basic settings associated with the instance that will be launched.
Modify the `xr_version` and `aws_ami_xrv9k` variables to make sure the instance is launched using the ami of your choice.
For example, in the file below, the default `xr_version` is set to `631`. The corresponding ami with id = `ami-894392f1` will be selected during instance launch.
This is essentially the AWS marketplace 6.3.1 release image for xrv9k: <https://aws.amazon.com/marketplace/pp/B077GJPZ7H>

```
aks::~/xrv9k-aws-topo/single_node$cat variables.tf 
variable "xr_version" {
  default = "631"
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
aks::~/xrv9k-aws-topo/single_node$

```


### Starting the Topology

Drop into any topology folder and run the `./xrv9k_bringup` script that will instantiate the xrv9k instance on AWS based on the terraform file settings discussed above.

```
aks::~/xrv9k-aws-topo$./xrv9k_bringup 
####################################################
Initializing terraform ...
####################################################
Disabling Terraform debugs

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v3.38.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
####################################################
Starting launch ... 
####################################################
aws_key_pair.aws_keypair: Creating...
aws_default_vpc.default: Creating...
aws_key_pair.aws_keypair: Creation complete after 3s [id=xrv9k_aws_amibuilder_20210505122046]
aws_default_vpc.default: Still creating... [10s elapsed]
aws_default_vpc.default: Still creating... [20s elapsed]
aws_default_vpc.default: Creation complete after 28s [id=vpc-4f2c5128]
aws_security_group.server_sg: Creating...
aws_security_group.server_sg: Still creating... [10s elapsed]
aws_security_group.server_sg: Creation complete after 11s [id=sg-081ed6fe01308dc01]
aws_instance.c5_xrv9k: Creating...
aws_instance.c5_xrv9k: Still creating... [10s elapsed]
aws_instance.xrv9k: Still creating... [20s elapsed]
aws_instance.xrv9k: Creation complete after 30s [id=i-0b602c2ba369e3728]
null_resource.deployment: Creating...
null_resource.deployment: Provisioning with 'remote-exec'...
null_resource.deployment (remote-exec): Connecting to remote host via SSH...
null_resource.deployment (remote-exec):   Host: 54.202.114.64
null_resource.deployment (remote-exec):   User: root
null_resource.deployment (remote-exec):   Password: false
null_resource.deployment (remote-exec):   Private key: true
null_resource.deployment (remote-exec):   Certificate: false
null_resource.deployment (remote-exec):   SSH Agent: false


.......


null_resource.deployment: Still creating... [12m29s elapsed]
null_resource.deployment: Still creating... [12m39s elapsed]
null_resource.deployment (remote-exec): Connecting to remote host via SSH...
null_resource.deployment (remote-exec):   Host: 54.202.114.64
null_resource.deployment (remote-exec):   User: root
null_resource.deployment (remote-exec):   Password: false
null_resource.deployment (remote-exec):   Private key: true
null_resource.deployment (remote-exec):   Certificate: false
null_resource.deployment (remote-exec):   SSH Agent: false
null_resource.deployment (remote-exec):   Checking Host Key: false
null_resource.deployment (remote-exec):   Target Platform: unix
null_resource.deployment (remote-exec): Connected!
null_resource.deployment: Creation complete after 12m44s [id=6767887524019924195]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
aks::~/xrv9k-aws-topo$

```


### Bring down the Topology

To bring down the entire topology simply run `./xrv9k_bringdown` in the relevant topology directory. This should remove/destroy all the AWS resources that were instantiated by the bringup script.

```
aks::~/xrv9k-aws-topo$./xrv9k_bringdown 
####################################################
Initializing terraform ...
####################################################
Disabling Terraform debugs

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/null v3.1.0
- Using previously-installed hashicorp/aws v3.38.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
####################################################
Bringing down setup ... 
####################################################

aws_default_vpc.default: Refreshing state... [id=vpc-4f2c5128]
aws_key_pair.aws_keypair: Refreshing state... [id=xrv9k_aws_amibuilder_20210505142609]
aws_security_group.server_sg: Refreshing state... [id=sg-07982856435972dcb]
aws_instance.xrv9k: Refreshing state... [id=i-0b602c2ba369e3728]
null_resource.deployment: Refreshing state... [id=6767887524019924195]
null_resource.deployment: Destroying... [id=6767887524019924195]
null_resource.deployment: Destruction complete after 0s
aws_instance.xrv9k: Destroying... [id=i-0b602c2ba369e3728]
aws_instance.xrv9k: Still destroying... [id=i-0b602c2ba369e3728, 10s elapsed]
aws_instance.xrv9k: Still destroying... [id=i-0b602c2ba369e3728, 20s elapsed]
aws_instance.xrv9k: Destruction complete after 26s
aws_security_group.server_sg: Destroying... [id=sg-07982856435972dcb]
aws_key_pair.aws_keypair: Destroying... [id=xrv9k_aws_amibuilder_20210505142609]
aws_key_pair.aws_keypair: Destruction complete after 1s
aws_security_group.server_sg: Destruction complete after 3s
aws_default_vpc.default: Destroying... [id=vpc-4f2c5128]
aws_default_vpc.default: Destruction complete after 0s

Destroy complete! Resources: 5 destroyed.
1 mins 18 seconds elapsed.
aks::~/xrv9k-aws-topo$

```
