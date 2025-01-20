# ec2 
variable "instance_type" {
    default = "t2.micro"
    description = "instance type"
    type = string
}

variable "ec2_tag" {
    default = {
        Name = "myec2"
    }
    description = "ec2 tag"
    type = map(string)
}


variable "subnet_id" {
    description = "Subnet ID"
    type = string
}

# sg
variable "mysg_tag" {
    default = {
        Name = "mysg"
    }
}
variable "sg_ids" {
    description = "Security Group IDs(list)"
    type = list
}

variable "keypair" {
    description = "EC2 Key Pair"
}