terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.84.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# VPC 만들기
resource "aws_vpc" "myVPC" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "myVPC"
    }
}

# 인터넷 게이트웨이 만들기
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

/* 필요없는것같은데
resource "aws_internet_gateway_attachment" "myIGW_Att" {
    internet_gateway_id = aws_internet_gateway.myIGW.id
    vpc_id = aws_vpc.myVPC.id
}
*/ 

# 서브넷1 만들기

resource "aws_subnet" "myPubSub1" {
    vpc_id = aws_vpc.myVPC.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-2a"

    tags = {
        Name = "myPubSub1"
    }
}

resource "aws_route_table" "myRT1" {
    vpc_id = aws_vpc.myVPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myIGW.id
    }

    tags = {
        Name = "myRT1"
    }
}

resource "aws_route_table_association" "myRT_binding1" {
    subnet_id = aws_subnet.myPubSub1.id
    route_table_id = aws_route_table.myRT1.id
}

# 서브넷2 만들기
resource "aws_subnet" "myPubSub2" {
    vpc_id = aws_vpc.myVPC.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-2b"
    tags = {
        Name = "myPubSub2"
    }
}

resource "aws_route_table" "myRT2" {
    vpc_id = aws_vpc.myVPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myIGW.id
    }

    tags = {
        Name = "myRT2"
    }
}

resource "aws_route_table_association" "myRT_binding2" {
    subnet_id = aws_subnet.myPubSub2.id
    route_table_id = aws_route_table.myRT2.id
}

# ami - data source
data "aws_ami" "amazon" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.6.*.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

# EC2를 위한 보안그룹
resource "aws_security_group" "http" {
  name        = "allow_http"
  description = "Allow http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "myEC2_1" {
  ami           = data.aws_ami.amazon.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.myPubSub1.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.http.id]

  user_data_replace_on_change = true

  user_data = <<EOF
#!/bin/bash
hostname EC2-1
sudo yum -y install httpd
sudo systemctl enable --now httpd
echo "this is ec2-1" > /var/www/html/index.html
EOF

  tags = {
    Name = "myEC2_1"
  }
}

resource "aws_instance" "myEC2_2" {
  ami           = data.aws_ami.amazon.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.myPubSub2.id
  security_groups = [aws_security_group.http.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = <<EOF
#!/bin/bash
hostname EC2-2
sudo yum -y install httpd
sudo systemctl enable --now httpd
echo "this is ec2-2" > /var/www/html/index.html
EOF
  tags = {
    Name = "myEC2_2"
  }
}

########## LB

# target group
resource "aws_lb_target_group" "myTG" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myVPC.id
}

resource "aws_lb_target_group_attachment" "myTG_attachment_1" {
  target_group_arn = aws_lb_target_group.myTG.arn
  target_id        = aws_instance.myEC2_1.id  # EC2-2
  port             = 80
}

resource "aws_lb_target_group_attachment" "myTG_attachment_2" {
  target_group_arn = aws_lb_target_group.myTG.arn
  target_id        = aws_instance.myEC2_2.id  # EC2-2
  port             = 80
}

# lb
resource "aws_lb" "mylb" {
  name               = "mylb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.http.id]
  subnets = [aws_subnet.myPubSub1.id , aws_subnet.myPubSub2.id ]
  
  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# listener
resource "aws_lb_listener" "myListener" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myTG.arn
  }
}


