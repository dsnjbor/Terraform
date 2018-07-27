provider "aws" {
shared_credentials_file  = "/home/ec2-user/.aws/credentials"
 region     = "${var.region}"
 profile    = "default"
}

resource "aws_security_group" "ForBalancer" {
name        = "For_Balancer"
 description = "A security group that will apply to the balancer"
 vpc_id      = "${var.myvpcid}"


# Allow HTTP from anywhere
 ingress {
from_port   = 80
   to_port     = 80
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
}


module "balancer1" {
source = "git::https://github.com/dsnjbor/Terra/terraform/test-module"
 modname   = "Balancer1"
 SecGroupId = "${aws_security_group.ForBalancer.id}"
}


module "balancer2" {
source = "git::https://github.com/dsnjbor/Terra/terraform/test-module"
 modname   = "Balancer2"
 SecGroupId = "${aws_security_group.ForBalancer.id}"
}