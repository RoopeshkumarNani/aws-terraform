terraform {
    required_providers {
      aws={
        source = "hashicorp/aws"
        version="~> 6.0"
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
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

output "ami_id" {
    value = data.aws_ami.amazon_linux.id
}

output "ami_name" {
    value=data.aws_ami.amazon_linux.name
}

output "ami_creationDate" {
  value = data.aws_ami.amazon_linux.creation_date
}

resource "aws_security_group" "ssg_eip_ec2" {
    name = "ssg-eip-ec2"
    description = "allowing inbound through SSH and all network through outbound"
    

    ingress{
        from_port = 22
        to_port = 22
        description = "ssh from anywhere (temporary)"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name="ssg-eip-ec2"
    }
}


resource "aws_instance" "eip_instance" {
    ami=data.aws_ami.amazon_linux.id
    instance_type="t3.micro"
    associate_public_ip_address=false
    vpc_security_group_ids=[aws_security_group.ssg_eip_ec2.id]
    tags = {
      Name="Demo-ec2-eip"
    }
}

resource "aws_eip" "ec2_eip" {
    domain="vpc"
}

resource "aws_eip_association" "eip_assoc" {
    instance_id = aws_instance.eip_instance.id
    allocation_id = aws_eip.ec2_eip.id
}


