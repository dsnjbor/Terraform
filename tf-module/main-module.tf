resource "aws_elb" "mybalancer" {
name = "${var.modname}"


 subnets         = ["${var.SubnetId}"]
 security_groups = ["${var.SecGroupId}"]


 listener {
instance_port     = 80
   instance_protocol = "http"
   lb_port           = 80
   lb_protocol       = "http"
 }


}