# VPC
# IGW & attch 
# public SN -> RT -> RT setting

# 1. VPC
resource "aws_vpc" "myvpc" {
  cidr_block       = var.vpc_cidr   # 10.0.0.0/16
  tags = var.vpc_tag                # vpc_tag
}

# IGW - Resource: aws_internet_gateway && attach
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myvpc.id
  tags = var.igw_tag
}

# 3. Public Subnet 
resource "aws_subnet" "mysubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = var.subnet_cidr
  availability_zone = "ap-northeast-2c"
  tags = var.subnet_tag
}

# 4 Public Routing Table - Resource: aws_route_table
resource "aws_route_table" "mypublic_RT" {
  vpc_id = aws_vpc.myvpc.id
  tags = var.routetable_tag

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }
}

# RT Association - Resource: aws_route_table_association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mysubnet.id
  route_table_id = aws_route_table.mypublic_RT.id
}

# Security Group 
resource "aws_security_group" "mysg" {
  name = "allow_web"
  description = "allow http/https inbound traffic and all outbound traffic"
  vpc_id = aws_vpc.myvpc.id

  tags = var.mysg_tag
}

# Security Group Ingress rule 
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
