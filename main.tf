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
    public_key = file("~/.ssh/tf-key.pub")
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