terraform {
  required_providers {
    aws={
        source = "hashicorp/aws"
        version = "~>6.0"
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

    filter{
        name = "name"
        values=["amzn2-ami-hvm-*-x86_64-gp3", "amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

resource "aws_iam_role" "ec2_dm_role" {
    name = "ec2-dm-role"
    assume_role_policy = jsonencode({
        Version="2012-10-17"
        Statement=[
            {
                Effect="Allow"
                Action="sts:AssumeRole"
                Principal={
                    Service="ec2.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ec2_attach_role" {
    role = aws_iam_role.ec2_dm_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_agent_policy"{
    role = aws_iam_role.ec2_dm_role.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_dm_profile"{
    name="ec2-cw-dm-profile-lab-06"
    role=aws_iam_role.ec2_dm_role.name
}

resource "aws_security_group" "ec2_cw_dm"{
    name="ec2-cw-dm-lab-06"
    description = "Allow inbound traffic through SSM and outbound traffic through all"

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags={
        Name="ec2-cw-dm-ssg-grp"
    }
}

resource "aws_instance" "ec2_dm_instance" {
    ami                         = data.aws_ami.amazon_linux.id
    instance_type               = "t3.micro"
    iam_instance_profile        = aws_iam_instance_profile.ec2_dm_profile.name
    vpc_security_group_ids      = [aws_security_group.ec2_cw_dm.id]
    associate_public_ip_address = true

    user_data = <<-EOF
      #!/bin/bash
      set -euxo pipefail
      yum update -y
      yum install -y amazon-cloudwatch-agent

      cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONF'
      {
        "agent": {
          "metrics_collection_interval": 60
        },
        "metrics": {
          "namespace": "CWAgent",
          "append_dimensions": {
            "InstanceId": "$${aws:InstanceId}"
          },
          "aggregation_dimensions": [["InstanceId"]],
          "metrics_collected": {
            "mem": {
              "measurement": ["mem_used_percent"]
            },
            "disk": {
              "measurement": ["used_percent"],
              "resources": ["*"]
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
        Name = "lab-06-ec2-cw-dm"
    }
}

resource "aws_sns_topic" "cw_alerts" {
    name = "lab-06-cw-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
    topic_arn = aws_sns_topic.cw_alerts.arn
    protocol  = "email"
    endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
    alarm_name          = "lab-06-cpu-high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 120
    statistic           = "Average"
    threshold           = 70
    alarm_description   = "EC2 CPU > 70%"
    alarm_actions       = [aws_sns_topic.cw_alerts.arn]

    dimensions = {
        InstanceId = aws_instance.ec2_dm_instance.id
    }
}

resource "aws_cloudwatch_metric_alarm" "status_instance_failed" {
    alarm_name          = "lab-06-status-instance-failed"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    metric_name         = "StatusCheckFailed_Instance"
    namespace           = "AWS/EC2"
    period              = 60
    statistic           = "Maximum"
    threshold           = 1
    alarm_description   = "EC2 instance status check failed"
    alarm_actions       = [aws_sns_topic.cw_alerts.arn]

    dimensions = {
        InstanceId = aws_instance.ec2_dm_instance.id
    }
}

resource "aws_cloudwatch_metric_alarm" "status_system_failed" {
    alarm_name          = "lab-06-status-system-failed"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    metric_name         = "StatusCheckFailed_System"
    namespace           = "AWS/EC2"
    period              = 60
    statistic           = "Maximum"
    threshold           = 1
    alarm_description   = "EC2 system status check failed"
    alarm_actions       = [aws_sns_topic.cw_alerts.arn]

    dimensions = {
        InstanceId = aws_instance.ec2_dm_instance.id
    }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
    alarm_name          = "lab-06-memory-high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name         = "mem_used_percent"
    namespace           = "CWAgent"
    period              = 120
    statistic           = "Average"
    threshold           = 80
    alarm_description   = "Memory utilization > 80%"
    alarm_actions       = [aws_sns_topic.cw_alerts.arn]

    dimensions = {
        InstanceId = aws_instance.ec2_dm_instance.id
    }
}

resource "aws_cloudwatch_metric_alarm" "disk_high" {
    alarm_name          = "lab-06-disk-high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name         = "disk_used_percent"
    namespace           = "CWAgent"
    period              = 120
    statistic           = "Average"
    threshold           = 80
    alarm_description   = "Disk utilization > 80%"
    alarm_actions       = [aws_sns_topic.cw_alerts.arn]

    dimensions = {
        InstanceId = aws_instance.ec2_dm_instance.id
    }
}

resource "aws_cloudwatch_composite_alarm" "infra_health" {
    alarm_name        = "lab-06-infra-health"
    alarm_description = "Composite alarm for CPU, status checks, memory, and disk."
    alarm_rule = join(" OR ", [
        "ALARM(${aws_cloudwatch_metric_alarm.cpu_high.alarm_name})",
        "ALARM(${aws_cloudwatch_metric_alarm.status_instance_failed.alarm_name})",
        "ALARM(${aws_cloudwatch_metric_alarm.status_system_failed.alarm_name})",
        "ALARM(${aws_cloudwatch_metric_alarm.memory_high.alarm_name})",
        "ALARM(${aws_cloudwatch_metric_alarm.disk_high.alarm_name})"
    ])
    alarm_actions = [aws_sns_topic.cw_alerts.arn]
}

output "instance_id" {
    value = aws_instance.ec2_dm_instance.id
}

output "public_ip" {
    value = aws_instance.ec2_dm_instance.public_ip
}

output "sns_topic_arn" {
    value = aws_sns_topic.cw_alerts.arn
}

output "composite_alarm_name" {
    value = aws_cloudwatch_composite_alarm.infra_health.alarm_name
}
