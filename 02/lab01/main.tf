
provider "aws" {
    region = "us-east-2"
}

# VPC 
resource "aws_vpc" "myVPC" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true

    tags = {
        Name = "myVPC"
    }
}

# 보안그룹 생성

resource "aws_security_group" "allow_http" {
    name = "allow_http"
    description = "this is allow http"
    vpc_id = aws_vpc.myVPC.id

    tags = {
        Name = "allow_http"
    }
}

# 보안그룹 역할 생성

resource "aws_security_group_rule" "myRule" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.allow_http.id
}



# internet gateway & vpc 연결 

resource "aws_internet_gateway" "myIGW" {
    vpc_id = aws_vpc.myVPC.id
}


# VPC pub subnet 

resource "aws_subnet" "myPubSub" {
    vpc_id = aws_vpc.myVPC.id
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true

    tags = {
        Name = "myPubSub"
    }
    
}


# routing table & 

resource "aws_route_table" "myPubRT" {
    vpc_id = aws_vpc.myVPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myIGW.id
    }
    
    tags = {
        Name = "myPubRT"
    }
}


# 서브넷에 연결

resource "aws_route_table_association" "asdf" {
    subnet_id = aws_subnet.myPubSub.id
    route_table_id = aws_route_table.myPubRT.id
    
}


resource "aws_instance" "myWEB" {
    ami = "ami-0d7ae6a161c5c4239"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.myPubSub.id
    user_data_replace_on_change = true
    user_data = <<-EOF
    #!/bin/bash
    yum -y install httpd mod_ssl
    echo "myweb" > /var/www/html/index.html
    systemctl enable --now httpd
    EOF 
    tags = {
        Name = "myWEB"
    }
    
    vpc_security_group_ids = [aws_security_group.allow_http.id]
}