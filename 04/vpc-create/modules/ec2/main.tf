
data "aws_ami" "myubuntu2404" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# ec2
resource "aws_instance" "myec2" {
  ami           = data.aws_ami.myubuntu2404.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id    # essential
  availability_zone = "ap-northeast-2c"
  vpc_security_group_ids = var.sg_ids
  associate_public_ip_address = true
  key_name = var.keypair
  user_data = file("./userdata.sh") # ?????/dev/userdata.sh 에 위치해야 함.-> root 모듈

  user_data_replace_on_change = true

  tags = var.ec2_tag
}



