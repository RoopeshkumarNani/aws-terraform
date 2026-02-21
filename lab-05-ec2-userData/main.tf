terraform {
  required_providers {
    aws={
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
  }
}

provider "aws" {
     region = "ap-southeast-1"
}

data "aws_ami" "amazon_linux"{
    most_recent = true
    owners = ["amazon"]
    filter{
        name ="name"
        values=["amzn2-ami-hvm-*-x86_64-gp3","amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

#IAM role (for EC2)
resource "aws_iam_role" "aws_cloudwatch_agent" {
    name="aws-cw-lab-05"

    assume_role_policy=jsonencode({
        Version="2012-10-17"
        Statement=[{
            Effect="Allow"
            Principal={
                Service="ec2.amazonaws.com"
            }
            Action="sts:AssumeRole"
        }]
    })
}

#Attach Cloud watch agent policy
resource "aws_iam_role_policy_attachment" "cw_agent_policy"   {
    role=aws_iam_role.aws_cloudwatch_agent.name
    policy_arn="arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#instance profile
resource "aws_iam_instance_profile" "lab05_profile" {
    name="lab-05-ec2-profile"
    role=aws_iam_role.aws_cloudwatch_agent.name
}

#security Group(Http only +outbound all)
resource "aws_security_group" "lab05_sg" {
    name="lab-05-ec2-sg"
    description = "Allow HTTP inbound and all outbound"

    ingress{
        from_port = 80
        to_port = 80
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

#cloudwatch log group
resource "aws_cloudwatch_log_group" "lab05_logs" {
    name = "/aws/ec2/lab-05-userdata" 
    retention_in_days=7
}

#Block 8:Ec2+user data(nginx+cw agent)

resource "aws_instance" "lab05_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.lab05_profile.name
  vpc_security_group_ids      = [aws_security_group.lab05_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    yum update -y
    amazon-linux-extras enable nginx1
    yum clean metadata
    yum install -y amazon-cloudwatch-agent
    yum install -y nginx

    systemctl enable nginx
    systemctl restart nginx

    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    echo "<h1>Lab 05 - EC2 User Data</h1><p>Instance: $INSTANCE_ID</p>" > /usr/share/nginx/html/index.html

    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONF'
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "/aws/ec2/lab-05-userdata",
                "log_stream_name": "{instance_id}/messages"
              },
              {
                "file_path": "/var/log/nginx/access.log",
                "log_group_name": "/aws/ec2/lab-05-userdata",
                "log_stream_name": "{instance_id}/nginx-access"
              },
              {
                "file_path": "/var/log/nginx/error.log",
                "log_group_name": "/aws/ec2/lab-05-userdata",
                "log_stream_name": "{instance_id}/nginx-error"
              }
            ]
          }
        }
      }
    }
    CWCONF

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
  EOF

  tags = {
    Name = "lab-05-ec2-userdata"
  }
}

#output
output "instance_id" {
  value = aws_instance.lab05_ec2.id
}

output "public_ip" {
  value = aws_instance.lab05_ec2.public_ip
}

output "public_dns" {
  value = aws_instance.lab05_ec2.public_dns
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.lab05_logs.name
}

