# Lab 07 - EC2 Launch Template + Auto Scaling Group + ALB

## Objective
Provision a highly available EC2 web tier using a Launch Template, Auto Scaling Group (ASG), and Application Load Balancer (ALB) in `ap-southeast-1`.

## Why This Lab Matters
This lab moves from a single EC2 instance to a scalable and resilient architecture:

- Launch Template standardizes EC2 configuration
- ASG maintains desired instance count and self-heals failed instances
- ALB distributes HTTP traffic across healthy targets
- Health checks ensure traffic only reaches healthy instances

## Architecture Flow
1. Terraform fetches latest Amazon Linux 2 AMI.
2. Security Groups are created:
   - ALB SG: allows inbound HTTP (`80`) from internet
   - EC2 SG: allows inbound HTTP (`80`) only from ALB SG
3. Launch Template defines EC2 settings and `user_data` to install/start Nginx.
4. Target Group is created with HTTP health checks on `/`.
5. ALB is created in default subnets.
6. ALB Listener (port 80) forwards traffic to Target Group.
7. ASG launches instances using Launch Template and registers them in Target Group.

## Resources Created
- `aws_launch_template.app_lt`
- `aws_autoscaling_group.app_asg`
- `aws_lb.app_alb`
- `aws_lb_listener.http`
- `aws_lb_target_group.app_tg`
- `aws_security_group.alb_sg`
- `aws_security_group.ec2_sg`
- `data.aws_vpc.default`
- `data.aws_subnets.default`
- `data.aws_ami.amazon_linux`

## Security Design
- Public internet can access only ALB on `80`.
- EC2 instances are not directly internet-exposed for app traffic.
- EC2 app port `80` is allowed only from ALB security group.

## Terraform Workflow (Professional)
```bash
terraform init
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply tfplan
