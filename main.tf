terraform {
    required_providers {
      aws ={
        source ="hashicorp/aws"
        version = "~> 6.0"
      }
    }
}


provider "aws"{
     region = "ap-southeast-1"       
}


# Cross-region setup
# provider "aws" {
#     alias  = "syd"
#     region = "ap-southeast-2"
# }
#
# data "aws_ami" "amazon_linux_syd" {
#     provider    = aws.syd
#     most_recent = true
#     owners      = ["amazon"]
#
#     filter {
#         name   = "name"
#         values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#     }
# }
#
# resource "aws_key_pair" "tf_key_syd" {
#     provider   = aws.syd
#     key_name   = "tf-key-syd"
#     public_key = file(pathexpand("~/.ssh/tf-key.pub"))
# }
#
# resource "aws_security_group" "ssh_sg_syd" {
#     provider    = aws.syd
#     name        = "allow-ssh-syd"
#     description = "Allow SSH access"
#
#     ingress {
#         from_port   = 22
#         to_port     = 22
#         protocol    = "tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }
#
#     egress {
#         from_port   = 0
#         to_port     = 0
#         protocol    = "-1"
#         cidr_blocks = ["0.0.0.0/0"]
#     }
# }
#
# resource "aws_instance" "ec2_instance_syd" {
#     provider                    = aws.syd
#     ami                         = data.aws_ami.amazon_linux_syd.id
#     instance_type               = "t3.micro"
#     key_name                    = aws_key_pair.tf_key_syd.key_name
#     associate_public_ip_address = true
#     vpc_security_group_ids      = [aws_security_group.ssh_sg_syd.id]
#
#     tags = {
#         Name = "terraform-demo-ec2-syd"
#     }
# }
#
# variable "syd_snapshot_id" {
#     type = string
# }
#
# resource "aws_ebs_volume" "extra_volume_syd_from_snapshot" {
#     provider          = aws.syd
#     availability_zone = aws_instance.ec2_instance_syd.availability_zone
#     snapshot_id       = var.syd_snapshot_id
#     type              = "gp3"
#
#     tags = {
#         Name = "terraform-demo-syd-volume-from-snapshot"
#     }
# }
#
# resource "aws_volume_attachment" "extra_volume_syd_attach" {
#     provider    = aws.syd
#     device_name = "/dev/sdf"
#     volume_id   = aws_ebs_volume.extra_volume_syd_from_snapshot.id
#     instance_id = aws_instance.ec2_instance_syd.id
# }

data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values= ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

output "ami_id" {
    value =data.aws_ami.amazon_linux.id  
}

output "ami_name"{
    value =data.aws_ami.amazon_linux.name
}

output "creation_date"{
    value=data.aws_ami.amazon_linux.creation_date
}

output "instance_id" {
    value=aws_instance.ec2_instance.id
}

# Creating  the resource

resource "aws_instance" "ec2_instance" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    key_name = aws_key_pair.tf_key.key_name

    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.ssh_sg.id]

    tags ={
        Name ="terraform-demo-ec2"
    }
}

resource "aws_key_pair" "tf_key"{
    key_name = "tf-key"
    public_key = file(pathexpand("~/.ssh/tf-key.pub"))
}

resource "aws_security_group" "ssh_sg" {
    name = "allow-sh"
    description= "Allow SSH access"
    
    ingress {
        description = "SSH from anywhere (temporary)"  
        from_port = 22     
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_ebs_volume" "extra_volume"{
    availability_zone = aws_instance.ec2_instance.availability_zone
    size = 8
    type = "gp2"
    encrypted=true
    
    tags={
        Name="terraform-demo-extra-ebs"
    }
}

resource "aws_volume_attachment" "extra_volume_attach" {
    device_name="/dev/sdf"
    volume_id= aws_ebs_volume.extra_volume.id
    instance_id=aws_instance.ec2_instance.id
}

#adding EFS to the instances
#EFS
resource "aws_efs_file_system" "lab_efs" {
    encrypted = true
    tags = {
      Name="lab-efs"
    }
}

resource "aws_security_group" "efs_sg" {
    name="efs-sg"
    vpc_id = aws_security_group.ssh_sg.vpc_id

    ingress {
        from_port = 2049
        to_port = 2049
        protocol = "tcp"
        security_groups = [aws_security_group.ssh_sg.id]
    }
     
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#mounting the target on the ec2 instance
resource "aws_efs_mount_target" "lab_efs_mt" {
    file_system_id = aws_efs_file_system.lab_efs.id
    subnet_id = aws_instance.ec2_instance.subnet_id
    security_groups = [aws_security_group.efs_sg.id]
}


output "efs_id" {
    value = aws_efs_file_system.lab_efs.id
}

#fsx Now let us add the fsx file system
resource "aws_fsx_lustre_file_system" "lab_fsx" {
    subnet_ids = [aws_instance.ec2_instance.subnet_id]
    security_group_ids = [aws_security_group.fsx_sg.id]
    storage_capacity = 1200
    deployment_type = "SCRATCH_2"

    tags={
        Name="lab-fsx-lustre"
    }
}

resource "aws_security_group" "fsx_sg" {
    name="fsx-sg"
    vpc_id = aws_security_group.ssh_sg.vpc_id

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        security_groups = [aws_security_group.ssh_sg.id]
    }
    
    egress{
        from_port = 0
        to_port =0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "fsx_dns_name" {
    value = aws_fsx_lustre_file_system.lab_fsx.dns_name
}

output "fsx_mount_name" {
    value = aws_fsx_lustre_file_system.lab_fsx.mount_name
}
