# VPC
variable "vpc_cidr" {
    default = "10.0.0.0/16"
    description = "vpc_cidr"
    type = string
}

variable "vpc_tag" {
    default = {
        Name = "myvpc"
    }
    description = "vpc_tag"
    type = map(string)
}


# IGW
variable "igw_tag" {
    default = {
        Name = "myIGW"
    }
    description = "IGW tag"
    type = map(string)
}

# SUBNET
variable "subnet_cidr" {
    default = "10.0.1.0/24"
    description = "VPC Public subnet"
    type = string
}

variable "subnet_tag" {
    default = {
        Name = "mysubnet"
    }
    description = "subnet tag"
    type = map(string)
}

# Routing Table
variable "routetable_tag" {
    default = {
        Name = "mypublic_RT"
    }
    description = "Public Routing Table tag"
    type = map(string)
}

# security group
variable "mysg_tag" {
    default = {
        Name = "mysg"
    }
}