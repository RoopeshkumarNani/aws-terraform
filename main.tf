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

