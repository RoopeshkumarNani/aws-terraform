terraform {
  required_providers {
    aws={
        source = "hashicorp/aws"
        version="~>6.0"
    }
  }
}

provider "aws" {
     region = "ap-southeast-1"
}

variable "alert_email" {
    type = string 
}

data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]
    filter {
       name ="name"
       values=["amzn2-ami-hvm-*-x86_64-gp3",
               "amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

resource "aws_security_group" "ec2_ssg" {
    name= "lab-04-ec2-sg"
    description = "No inbound outbound allowed"

    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "lab4_ec2"{
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.ec2_ssg.id]
    associate_public_ip_address = true

    tags={
        Name="lab-04-ec2-cloudwatch"
    }
}

#creates an sns  topic
resource "aws_sns_topic" "cpu_alerts" {
    name="lab-04-cpu-alerts"
}

#subscribes your email to the sns topic
resource "aws_sns_topic_subscription" "email_alert" {
    topic_arn = aws_sns_topic.cpu_alerts.arn
    protocol = "email"
    endpoint=var.alert_email
}

#Creates CPU alarm on that instance,watches metric alarm condition and all
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
    alarm_name = "lab-04-high-cpu"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 2
    metric_name="CPUUtilization"
    namespace = "AWS/EC2"
    period = 120
    statistic = "Average"
    threshold = 70
    alarm_description = "Alarm when EC2 CPU > 70%"
    alarm_actions = [aws_sns_topic.cpu_alerts.arn]

    dimensions={
        InstanceId=aws_instance.lab4_ec2.id
    }
}

output "instance_id" {
  value = aws_instance.lab4_ec2.id
}

output "sns_topic_arn"{
    value = aws_sns_topic.cpu_alerts.arn
}