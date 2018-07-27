#--------------------------------------------------------------
# EC2 Instance Module
#--------------------------------------------------------------

# Security group
resource "aws_security_group" "instance_sg" {
  name        = "${var.name}"
  vpc_id      = "${var.vpc_id}"
  description = "${var.name} security group"

  tags = "${merge(map("Name", "${var.name}"), var.tags)}"
}

# Security group source rules
resource "aws_security_group_rule" "security_group_rule_sg" {
  count                    = "${length(var.security_group_rules_sg)}"
  type                     = "${lookup(var.security_group_rules_sg[count.index],"type")}"
  from_port                = "${lookup(var.security_group_rules_sg[count.index],"from_port")}"
  to_port                  = "${lookup(var.security_group_rules_sg[count.index],"to_port")}"
  protocol                 = "${lookup(var.security_group_rules_sg[count.index],"protocol")}"
  source_security_group_id = "${lookup(var.security_group_rules_sg[count.index],"source_security_group_id")}"
  security_group_id        = "${aws_security_group.instance_sg.id}"
}

# CIDR block security group rules
resource "aws_security_group_rule" "security_group_rule_cidr" {
  count             = "${length(var.security_group_rules_cidr)}"
  type              = "${lookup(var.security_group_rules_cidr[count.index],"type")}"
  from_port         = "${lookup(var.security_group_rules_cidr[count.index],"from_port")}"
  to_port           = "${lookup(var.security_group_rules_cidr[count.index],"to_port")}"
  protocol          = "${lookup(var.security_group_rules_cidr[count.index],"protocol")}"
  cidr_blocks       = ["${lookup(var.security_group_rules_cidr[count.index],"cidr_blocks")}"]
  security_group_id = "${aws_security_group.instance_sg.id}"
}

#--------------------------------------------------------------
# Instance resource
#--------------------------------------------------------------
resource "aws_instance" "instance" {
  ami                     = "${var.ami}"
  instance_type           = "${var.instance_type}"
  key_name                = "${var.key_name}"
  subnet_id               = "${var.subnet_id}"
  availability_zone       = "${var.availability_zone}"
  vpc_security_group_ids  = ["${aws_security_group.instance_sg.id}"]
  disable_api_termination = "${var.disable_api_termination}"
  private_ip              = "${var.private_ip}"
  monitoring              = "${var.detailed_monitoring}"
  user_data               = "${var.user_data}"
  ebs_optimized           = "${var.ebs_optimized}"
  iam_instance_profile    = "${var.iam_instance_profile}"
  tags                    = "${merge(map("Name", var.name), merge(map("scheduler:ebs-snapshot", var.create_snapshots), var.tags))}"
  volume_tags             = "${merge(map("Name", var.name), var.tags)}"

  root_block_device {
    volume_size           = "${var.root_volume_size}"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "${var.data_volume_name}"
    volume_size           = "${var.data_volume_size}"
    volume_type           = "gp2"
    delete_on_termination = true
    encrypted             = true
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_eip_association" "eip_assoc" {
  count         = "${var.associate_elastic_ip}"
  instance_id   = "${aws_instance.instance.id}"
  allocation_id = "${aws_eip.eip.id}"
}

resource "aws_eip" "eip" {
  count = "${var.associate_elastic_ip}"
  vpc   = true

  lifecycle {
    prevent_destroy = false
  }
}

# Optionaly attach instance to a ELB
resource "aws_elb_attachment" "elb_attachment" {
  count    = "${var.attach_to_elb}"
  elb      = "${var.elb_id}"
  instance = "${aws_instance.instance.id}"
}

resource "aws_cloudwatch_metric_alarm" "autorecover" {
  count              = "${var.enable_autorecovery}"
  alarm_name         = "${var.name}-ec2-autorecover"
  namespace          = "AWS/EC2"
  evaluation_periods = "1"
  period             = "60"
  alarm_description  = "Auto recovery for instance ${var.name} / ${aws_instance.instance.id} in environment ${var.env} ${var.region}"

  alarm_actions = ["arn:aws:automate:${var.region}:ec2:recover",
    "${var.alarm_autorecovery_actions}",
  ]

  insufficient_data_actions = ["${var.alarm_autorecovery_actions}"]
  ok_actions                = ["${var.alarm_autorecovery_actions}"]
  statistic                 = "Minimum"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = "0"
  metric_name               = "StatusCheckFailed"

  dimensions {
    InstanceId = "${aws_instance.instance.id}"
  }
}
resource "aws_alb" "alb" {
  name            = "${var.name}-alb-${var.environment}"
  internal        = true
  security_groups = ["${var.security_group_id}"]
  subnets         = ["${split(",", var.subnet_ids)}"]
tags {
    Environment = "${var.environment}"
  }
}
resource "aws_alb_target_group" "alb_targets" {
  count     = "${length(keys(var.services_map))}"
  name      = "${element(values(var.services_map), count.index)}-${var.environment}"
  port      = "${element(keys(var.services_map), count.index)}"
  protocol  = "HTTP"
  vpc_id    = "${var.vpc_id}"
health_check {
    healthy_threshold   = 2
    interval            = 15
    path                = "/api/health"
    timeout             = 10
    unhealthy_threshold = 2
  }
tags {
    Color       = "${var.color}"
    Service     = "${element(values(var.services_map), count.index)}"
    Tier        = "${var.name}"
    Environment = "${var.environment}"
  }
}
resource "aws_alb_listener" "alb_listener" {
  count             = "1"
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "${element(keys(var.services_map), count.index)}"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${var.ssl_certificate_arn}"
default_action {
    target_group_arn = "${element(aws_alb_target_group.alb_targets.*.arn, 0)}"
    type = "forward"
  }
}
resource "aws_alb_listener_rule" "route_path" {
  count         = "${length(values(var.services_map))}"
  listener_arn  = "${aws_alb_listener.alb_listener.arn}"
  priority      = "${1 + count.index}"
action {
    type = "forward"
    target_group_arn = "${element(aws_alb_target_group.alb_targets.*.arn, count.index)}"
  }
condition {
    field = "host-header"
    values = ["${element(values(var.services_map), count.index)}.${var.domain}"]
  }
lifecycle {
    ignore_changes = ["priority"]
  }
}

#--------------------------------------------------------------
# Module output
#--------------------------------------------------------------
output "id" {
  value = "${aws_instance.instance.id}"
}

output "security_group_id" {
  value = "${aws_security_group.instance_sg.id}"
}

