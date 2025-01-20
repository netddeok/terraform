terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.83.1"
        }
    }
}

provider "aws" {
    region = var.region
}

#
# 기본 인프라
#

data "aws_vpc" "default" { # ref : aws_vpc 
    default = true
}

data "aws_subnets" "default" {  # ref : aws_subnets
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 1 보안 그룹 생성

resource "aws_security_group" "myasg_sg" {
  name        = "myasg_sg"
  description = "Allow SSH,HTTP inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myasg_sg"
  }
}

# ingress
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.myasg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.myasg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_port
  ip_protocol       = "tcp"
  to_port           = var.web_port
}

# egress
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.myasg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

data "aws_ami" "amazone_2023_ami" {
  most_recent      = true
  owners           = [var.amazon]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.6.20250107.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "myasg_template" {

  name = "myasg_template"
  instance_type = "t2.micro"
  image_id = data.aws_ami.amazone_2023_ami.id
  vpc_security_group_ids = [aws_security_group.myasg_sg.id]

  user_data = filebase64("./userdata.sh")
    lifecycle {
        create_before_destroy = true
    }

}

### 3) ASG 생성

resource "aws_autoscaling_group" "myasg" {
  name                      = "myasg"
  min_size                  = var.min_instance
  max_size                  = var.max_instance
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.mylb_tg.arn]
  depends_on = [aws_lb_target_group.mylb_tg]

  launch_template {
    id = aws_launch_template.myasg_template.id
  }

                ####### warning ######
                # load_balancers     #


  tag {
    key                 = "Name"
    value               = "myASG"
    propagate_at_launch = true
  }
}

#####
#       2. ALB 생성
#####

resource "aws_lb_target_group" "mylb_tg" {
  name     = "mylb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb" "mylb" {
    name = "mylb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.myasg_sg.id]
    subnets = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "mylb_listener" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = var.web_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    }
  }
}


resource "aws_lb_listener_rule" "mylb_listener_rule" {
  listener_arn = aws_lb_listener.mylb_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mylb_tg.arn
  }

  condition {
    path_pattern {
      values = ["/index.html"]
    }
  }
}