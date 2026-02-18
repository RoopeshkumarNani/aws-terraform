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
