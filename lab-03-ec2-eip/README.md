# Lab 03 - EC2 + Elastic IP

## Objective
Provision an EC2 instance in `ap-southeast-1`, allocate an Elastic IP, and associate it with the instance using Terraform.

## Why This Lab Matters
- Demonstrates static public IP management for EC2.
- Shows separation of EIP allocation and association.
- Builds practical Terraform lifecycle skills (create, verify, destroy).

## Resources Created
- `aws_instance.eip_instance` (`t3.micro`)
- `aws_security_group.ssg_eip_ec2`
- `aws_eip.ec2_eip`
- `aws_eip_association.eip_assoc`
- AMI lookup using `data.aws_ami.amazon_linux`

## Terraform Flow
```bash
terraform init
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply tfplan
