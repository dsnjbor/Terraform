#--------------------------------------------------------------
# Instance variables
#--------------------------------------------------------------
variable "ami" {
  default = "ami-e4515e0e"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "env" {}

variable "name" {}

variable "region" {}

variable "key_name" {
  default = "ontk8s"
}

variable "vpc_id" {
  default = "vpc-0561a8d3d39a5c629"
}

variable "subnet_id" {
  default = "subnet-06004cf4c2101e422"
}

variable "availability_zone" {
  default = "eu-west-1c"
}

variable "associate_elastic_ip" {
  default = false
}

variable "disable_api_termination" {
  default = true
}

variable "private_ip" {
  default = ""
}

variable "detailed_monitoring" {
  default = false
}

variable "user_data" {
  default = ""
}

variable "iam_instance_profile" {
  default = ""
}

variable "security_group_rules_sg" {
  type    = "list"
  default = []
}

variable "security_group_rules_cidr" {
  type    = "list"
  default = []
}

variable "tags" {
  type = "map"
  default = {
      environment = "test"
  }
}

variable "root_volume_size" {
  default = 100
}

variable "data_volume_name" {
  default = "/dev/xvdb"
}

variable "data_volume_size" {
  default = 20
}

variable "ebs_optimized" {
  default = false
}

variable "enable_autorecovery" {
  default = false
}

variable "alarm_autorecovery_actions" {
  type    = "list"
  default = []
}

variable "attach_to_elb" {
  default = true
}

# Allowed values described in doc directory (ebs-snapshot-scheduler.pdf)
variable "create_snapshots" {
  default = "False"
}

variable "elb_id" {}



