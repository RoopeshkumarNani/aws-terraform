# Lab 05 - EC2 User Data + Nginx + CloudWatch Logs

## Objective
Provision an EC2 instance in `ap-southeast-1` using Terraform, bootstrap it with `user_data`, serve a web page using Nginx, and ship logs to CloudWatch Logs using the CloudWatch Agent.

## Why This Lab Matters
This lab demonstrates a real-world EC2 provisioning pattern:

- Infrastructure as Code with Terraform
- Boot-time automation using `user_data`
- Application setup (Nginx) without manual SSH steps
- Centralized log collection in CloudWatch Logs
- IAM role-based permissions instead of static credentials

## Architecture Flow
1. Terraform creates IAM role and instance profile for EC2.
2. Terraform creates EC2 security group and CloudWatch log group.
3. Terraform launches EC2 and runs `user_data` at first boot.
4. `user_data` installs and starts Nginx, writes custom index page.
5. `user_data` installs and configures CloudWatch Agent.
6. CloudWatch Agent sends instance/system/nginx logs to CloudWatch Logs.

## Resources Created
- `aws_instance.lab05_ec2`
- `aws_security_group.lab05_sg`
- `aws_iam_role.aws_cloudwatch_agent`
- `aws_iam_role_policy_attachment.cw_agent_policy`
- `aws_iam_instance_profile.lab05_profile`
- `aws_cloudwatch_log_group.lab05_logs`
- `data.aws_ami.amazon_linux`

## Security Notes
- Inbound traffic is allowed only on port `80` (HTTP) for testing.
- Outbound traffic is open to allow package install and CloudWatch communication.
- No static AWS credentials are used on instance; IAM role is attached via instance profile.

## Terraform Workflow (Professional)
```bash
terraform init
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply tfplan
