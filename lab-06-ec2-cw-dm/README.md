# Lab 06 - EC2 + CloudWatch Alarms (Deep Monitoring)

## Objective
Provision an EC2 instance in `ap-southeast-1` with deep monitoring and alerting using CloudWatch, CloudWatch Agent, and SNS email notifications.

## Why This Lab Matters
This lab demonstrates production-style observability for EC2:

- Infrastructure provisioning with Terraform
- EC2 health and performance alarms
- Custom instance metrics (memory, disk) via CloudWatch Agent
- Centralized alerting using SNS email
- Composite alarm for consolidated incident signal

## Architecture Flow
1. Terraform creates IAM role + instance profile for EC2.
2. Terraform attaches:
   - `AmazonSSMManagedInstanceCore`
   - `CloudWatchAgentServerPolicy`
3. Terraform launches EC2 (`t3.micro`) and configures CloudWatch Agent via `user_data`.
4. CloudWatch Agent publishes memory/disk metrics to `CWAgent` namespace.
5. Terraform creates SNS topic + email subscription.
6. Terraform creates metric alarms and a composite alarm.
7. Alarm actions publish to SNS -> email notification.

## Resources Created
- `aws_instance.ec2_dm_instance`
- `aws_iam_role.ec2_dm_role`
- `aws_iam_role_policy_attachment.ec2_attach_role`
- `aws_iam_role_policy_attachment.cw_agent_policy`
- `aws_iam_instance_profile.ec2_dm_profile`
- `aws_security_group.ec2_cw_dm`
- `aws_sns_topic.cw_alerts`
- `aws_sns_topic_subscription.email_alert`
- `aws_cloudwatch_metric_alarm.cpu_high`
- `aws_cloudwatch_metric_alarm.status_instance_failed`
- `aws_cloudwatch_metric_alarm.status_system_failed`
- `aws_cloudwatch_metric_alarm.memory_high`
- `aws_cloudwatch_metric_alarm.disk_high`
- `aws_cloudwatch_composite_alarm.infra_health`

## Alarm Set (Deep Monitoring)
### EC2 native metrics (`AWS/EC2`)
- CPU alarm: `CPUUtilization > 70`
- Instance status check alarm: `StatusCheckFailed_Instance >= 1`
- System status check alarm: `StatusCheckFailed_System >= 1`

### CloudWatch Agent metrics (`CWAgent`)
- Memory alarm: `mem_used_percent > 80`
- Disk alarm: `disk_used_percent > 80`

### Composite alarm
- Triggers if **any** of the above alarms is in `ALARM` state.

## Prerequisites
- AWS CLI configured (`aws sts get-caller-identity`)
- Terraform installed
- Valid email for SNS subscription confirmation

## Terraform Workflow (Professional)
```bash
terraform init
terraform fmt
terraform validate
terraform plan -var='alert_email=YOUR_EMAIL@example.com' -out tfplan
terraform apply tfplan
