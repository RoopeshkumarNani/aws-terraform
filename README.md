# Terraform AWS EC2 Lab

## Goal
Provision an EC2 instance on AWS using Terraform.

## Stack
- Terraform
- AWS CLI
- AWS EC2, Security Group, Key Pair

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

## Commands Practice
Using professional Terraform flow:
- `terraform plan -out tfplan`
- `terraform apply tfplan`
- `terraform plan -destroy -out destroy.tfplan`
- `terraform apply destroy.tfplan`
