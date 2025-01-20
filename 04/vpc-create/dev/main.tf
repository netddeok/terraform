module "my_vpc" {
    source = "../modules/vpc"
    vpc_cidr = "192.168.0.0/24"    # overwrite 
    subnet_cidr = "192.168.0.0/25" # overwrite 
}

module "my_ec2" {
    source = "../modules/ec2"
    subnet_id = module.my_vpc.mysubnet_id
    sg_ids = [module.my_vpc.sg_id]
    keypair = "mykeypair"
}