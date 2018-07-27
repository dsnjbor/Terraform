variable "access_key" { 
  description = "AWS access key"
}

variable "secret_key" { 
  description = "AWS secret access key"
}

variable "region"     { 
  description = "AWS region to host your network"
  default     = "eu-west-1" 
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.226.128.0/19"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet"
  default     = "10.226.131.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for private subnet"
  default     = "10.226.132.0/24"
}

/* Ubuntu 14.04 amis by region */
variable "amis" {
  description = "Base AMI to launch the instances with"
  default = {
    eu-west-1 = "ami-e4515e0e" 
    }
}