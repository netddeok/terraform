# vpc outputs 
output "myvpc_id" {
    value = aws_vpc.myvpc.id
    description = "VPC ID"
}

# subnet outputs
output "mysubnet_id" {
    value = aws_subnet.mysubnet.id
    description = "Subnet ID"
}

output "sg_id" {
    value = aws_security_group.mysg.id
}