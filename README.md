# Terraform AWS EC2 Lab

## Goal
Provision an EC2 instance on AWS using Terraform.

## Stack
- Terraform
- AWS CLI
- AWS EC2, Security Group, Key Pair
- AWS EBS (extra volume + attachment)
- AWS EFS (file system + mount target)
- AWS FSx for Lustre

## Files
- main.tf
- .terraform.lock.hcl

## Commands Used
- terraform init
- terraform validate
- terraform plan -out tfplan
- terraform apply tfplan
- terraform plan -destroy -out destroy.tfplan
- terraform apply destroy.tfplan

## Notes
Region: ap-southeast-1

## Progress Log

### Lab 1: EC2 + Security Group + Key Pair
- Provisioned EC2 (`t3.micro`) in `ap-southeast-1`
- Used a data source for the latest Amazon Linux 2 AMI
- Verified create/apply/destroy lifecycle
- Practiced AWS CLI stop/start and instance state checks

### Lab 2: Extra EBS Volume
- Created an additional EBS volume (`gp3`, 10 GB, encrypted)
- Attached the EBS volume to the EC2 instance
- Verified volume attachment in AWS Console and AWS CLI

### Lab 3: Multi-Region (Singapore -> Sydney)
- Added a second AWS provider alias for `ap-southeast-2` (Sydney)
- Created a second EC2 instance in Sydney with its own key pair and security group
- Created an EBS snapshot in Singapore and copied it to Sydney
- Provisioned a new EBS volume in Sydney from the copied snapshot
- Attached the Sydney volume to the Sydney EC2 instance
- Practiced troubleshooting Terraform variable input issues (snapshot ID formatting)

### Lab 4: EFS and FSx (Storage Services)
- Added EFS file system and mount target in the EC2 subnet
- Added EFS security group rule for NFS (`2049`) from the EC2 security group
- Added FSx for Lustre resource and dedicated FSx security group
- Added outputs for EFS ID and FSx DNS/mount name

## Commands Practice
Using professional Terraform flow:
- `terraform plan -out tfplan`
- `terraform apply tfplan`
- `terraform plan -destroy -out destroy.tfplan`
- `terraform apply destroy.tfplan`

## Multi-Region Notes
- Source region: `ap-southeast-1` (Singapore)
- Destination region: `ap-southeast-2` (Sydney)
- Keep Terraform as the source of truth for create/update/destroy
- Use AWS CLI for operational checks and start/stop actions
