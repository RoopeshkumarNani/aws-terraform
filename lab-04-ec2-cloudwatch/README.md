# Lab 04 - EC2 + CloudWatch Alarm + SNS Email Alerts

## Objective
Provision an EC2 instance and configure monitoring so that high CPU usage triggers a CloudWatch alarm and sends an email notification through SNS.

## Why This Lab Matters
This lab demonstrates the full monitoring alert pipeline on AWS:

1. EC2 publishes metrics to CloudWatch (e.g., `CPUUtilization`)
2. CloudWatch Alarm evaluates threshold conditions
3. CloudWatch Alarm invokes SNS action
4. SNS delivers email notification to subscribers

This is a common production pattern for observability and incident response.

## Architecture Flow
- Terraform creates an EC2 instance in `ap-southeast-1`
- Terraform creates an SNS topic for alerts
- Terraform subscribes your email to the SNS topic
- Terraform creates a CloudWatch metric alarm on EC2 CPU
- When CPU remains above threshold, alarm changes to `ALARM`
- SNS sends an email alert

## Resources Created
- `aws_instance.lab4_ec2` (`t3.micro`)
- `aws_security_group.ec2_sg` (no inbound, outbound allowed)
- `aws_sns_topic.cpu_alerts`
- `aws_sns_topic_subscription.email_alert`
- `aws_cloudwatch_metric_alarm.high_cpu`
- `data.aws_ami.amazon_linux`

## Input Variable
- `alert_email` (required): email to receive alert notifications

## Alarm Configuration (Important)
The alarm is configured as:
- Metric: `CPUUtilization`
- Namespace: `AWS/EC2`
- Statistic: `Average`
- Period: `120` seconds
- Evaluation Periods: `2`
- Threshold: `70`
- Condition: `GreaterThanThreshold`

Meaning:
- If average CPU is > 70% for 2 consecutive 120-second periods, alarm goes to `ALARM` state.
- Then SNS action is triggered.

## Pre-Requisites
- AWS CLI configured and authenticated:
  - `aws sts get-caller-identity`
- Terraform installed
- Access to the email inbox used in `alert_email`

## Terraform Commands (Professional Flow)

Initialize and validate:
```bash
terraform init
terraform fmt
terraform validate
