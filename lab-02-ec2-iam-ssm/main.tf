terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role-lab-02"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-profile-lab-02"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_security_group" "ec2_no_ssh_sg" {
  name        = "ec2-no-ssh-sg-lab-02"
  description = "No inbound SSH; outbound allowed for SSH connection"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ec2-no-ssh-sg-labe-02"
  }
}

resource "aws_instance" "ec2_ssm_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  vpc_security_group_ids      = [aws_security_group.ec2_no_ssh_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "terrafoorm-labe-02-ec2-ssm"
  }
}

output "instance_id" {
  value = aws_instance.ec2_ssm_instance.id
}

output "instance_name" {
  value = aws_instance.ec2_ssm_instance.tags.Name
}

