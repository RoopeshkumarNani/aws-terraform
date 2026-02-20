# Lab 02 - EC2 + IAM + SSM (No SSH)

## Objective
Provision an EC2 instance in `ap-southeast-1` and access it securely through AWS Systems Manager Session Manager without opening inbound SSH (`22`).

## Why This Lab Matters
- Demonstrates secure EC2 access using IAM + SSM instead of public SSH.
- Shows least-privilege style setup with AWS-managed SSM policy.
- Matches real-world operational patterns and recruiter expectations.

## Architecture (Simple Flow)
- Terraform creates EC2 + IAM role + instance profile + security group.
- EC2 assumes IAM role through instance profile.
- SSM Agent on EC2 uses role permissions to register with Systems Manager.
- You open a shell using `aws ssm start-session` (no SSH port required).

## Resources Created
- `aws_instance.ec2_ssm_instance` (`t3.micro`)
- `aws_iam_role.ec2_ssm_role`
- `aws_iam_role_policy_attachment.ssm_core`
- `aws_iam_instance_profile.ec2_ssm_profile`
- `aws_security_group.ec2_no_ssh_sg`
- Outputs: `instance_id`, `instance_name`

## Prerequisites
- AWS CLI authenticated (`aws sts get-caller-identity`)
- Terraform installed
- Session Manager plugin installed on local machine

## Commands (Professional Flow)
```bash
terraform init
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

Get instance ID:
```bash
terraform output -raw instance_id
```

Start SSM session:
```bash
aws ssm start-session --target <instance-id> --region ap-southeast-1
```

Destroy:
```bash
terraform plan -destroy -out destroy.tfplan
terraform apply destroy.tfplan
```

## Validation Checklist
- EC2 is running in `ap-southeast-1`.
- Security group has no inbound SSH rule.
- IAM role includes `AmazonSSMManagedInstanceCore`.
- Session Manager opens successfully from CLI.

## Troubleshooting
- `SessionManagerPlugin is not found`: install Session Manager plugin.
- `MalformedPolicyDocument`: verify IAM trust policy uses `Statement` and `ec2.amazonaws.com`.
- SSM session not ready immediately: wait 1-2 minutes after instance launch.

## What I Learned
- Difference between IAM role and IAM instance profile for EC2.
- How Session Manager replaces SSH for secure access.
- How to validate and operate infrastructure using Terraform + AWS CLI.
