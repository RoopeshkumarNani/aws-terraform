# Terraform + AWS CLI Master Command Journal (Labs 1-7)

This file contains a deduplicated list of commands used across your 7 EC2 labs.

## 1) Navigation

`cd /mnt/c/Users/NANI/OneDrive/Desktop/terraform-course/terraform-aws-ec2`
- Move to repo root in WSL.

`cd /mnt/c/Users/NANI/OneDrive/Desktop/terraform-course/terraform-aws-ec2/lab-02-ec2-iam-ssm`
- Move to Lab 02 folder.

`cd /mnt/c/Users/NANI/OneDrive/Desktop/terraform-course/terraform-aws-ec2/lab-03-ec2-eip`
- Move to Lab 03 folder.

`cd /mnt/c/Users/NANI/OneDrive/Desktop/terraform-course/terraform-aws-ec2/lab-04-ec2-cloudwatch`
- Move to Lab 04 folder.

`cd /mnt/c/Users/NANI/OneDrive/Desktop/terraform-course/terraform-aws-ec2/lab-05-ec2-userData`
- Move to Lab 05 folder.

`cd /mnt/c/Users/NANI/OneDrive/Desktop/terraform-course/terraform-aws-ec2/lab-06-ec2-cw-dm`
- Move to Lab 06 folder.

`cd /mnt/c/Users/NANI/OneDrive/Desktop/terraform-course/terraform-aws-ec2/lab-07-LT+Asg+ALB`
- Move to Lab 07 folder.

## 2) Core Terraform Workflow

`terraform version`
- Check Terraform installation/version.

`terraform init`
- Initialize provider/plugins in current lab folder.

`terraform fmt`
- Format Terraform files.

`terraform fmt -check`
- Check formatting without editing files.

`terraform validate`
- Validate Terraform syntax and references.

`terraform plan -out tfplan`
- Generate and save reviewed plan.

`terraform show tfplan`
- Inspect saved plan details.

`terraform apply tfplan`
- Apply exactly the saved plan.

`terraform output`
- Show all Terraform outputs.

`terraform output -raw <output_name>`
- Print single output value as plain text.

## 3) Terraform Variables, State, and Drift

`terraform plan -var='alert_email=YOUR_EMAIL@example.com' -out tfplan`
- Create plan with input variable (Labs 04/06).

`terraform plan -destroy -var='alert_email=YOUR_EMAIL@example.com' -out destroy.tfplan`
- Create destroy plan with variable for alerting labs.

`terraform state list`
- List resources tracked in current state.

`terraform state show <resource_address>`
- Show detailed state for one resource.

`terraform plan -refresh-only -out refresh.tfplan`
- Refresh state vs AWS and detect drift.

`terraform show refresh.tfplan`
- Review refresh-only changes.

`terraform providers`
- Show providers required by configuration.

`terraform apply -replace=<resource_address> tfplan`
- Force replacement of one resource using saved plan.

## 4) Destroy / Cleanup

`terraform plan -destroy -out destroy.tfplan`
- Create destroy plan (professional flow).

`terraform apply destroy.tfplan`
- Destroy using reviewed destroy plan.

`terraform destroy`
- One-command destroy (quick flow).

## 5) AWS Identity / Region Checks

`aws sts get-caller-identity`
- Confirm active AWS account and identity.

`REGION=ap-southeast-1`
- Set region variable in shell.

## 6) EC2 Operations (Status, Stop, Start, Terminate)

`IID=$(terraform output -raw instance_id)`
- Capture instance ID from Terraform output.

`aws ec2 describe-instances --region "$REGION" --instance-ids "$IID" --query "Reservations[].Instances[].{State:State.Name,PublicIP:PublicIpAddress,Type:InstanceType,AZ:Placement.AvailabilityZone}" --output table`
- Check instance state/details.

`aws ec2 describe-instance-status --region "$REGION" --instance-ids "$IID" --include-all-instances --query "InstanceStatuses[].{InstanceState:InstanceState.Name,InstanceStatus:InstanceStatus.Status,SystemStatus:SystemStatus.Status}" --output table`
- Check EC2 status checks.

`aws ec2 stop-instances --region "$REGION" --instance-ids "$IID"`
- Stop instance.

`aws ec2 wait instance-stopped --region "$REGION" --instance-ids "$IID"`
- Wait until instance is stopped.

`aws ec2 start-instances --region "$REGION" --instance-ids "$IID"`
- Start instance.

`aws ec2 wait instance-running --region "$REGION" --instance-ids "$IID"`
- Wait until instance is running.

`aws ec2 terminate-instances --region "$REGION" --instance-ids <id1> <id2>`
- Terminate selected instances.

`aws ec2 wait instance-terminated --region "$REGION" --instance-ids <id1> <id2>`
- Wait until termination completes.

## 7) EBS and Snapshot Commands (Lab 03 history)

`VOL_ID=$(terraform state show -no-color aws_ebs_volume.extra_data | awk -F'=' '/^[[:space:]]*id[[:space:]]*=/{gsub(/["[:space:]]/,"",$2); print $2; exit}')`
- Extract EBS volume ID from Terraform state.

`aws ec2 create-snapshot --region "$SOURCE_REGION" --volume-id "$VOL_ID" --description "extra-ebs-snapshot" --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=extra-ebs-snapshot}]' --query SnapshotId --output text`
- Create snapshot in source region.

`aws ec2 wait snapshot-completed --region "$SOURCE_REGION" --snapshot-ids "$SNAP_ID"`
- Wait for snapshot completion.

`aws ec2 copy-snapshot --region "$DEST_REGION" --source-region "$SOURCE_REGION" --source-snapshot-id "$SNAP_ID" --description "copy-of-extra-ebs-snapshot" --query SnapshotId --output text`
- Copy snapshot to destination region.

`aws ec2 describe-snapshots --region "$DEST_REGION" --snapshot-ids "$COPY_SNAP_ID" --output table`
- Verify copied snapshot.

`aws ec2 delete-snapshot --region <region> --snapshot-id <snapshot-id>`
- Delete snapshot.

## 8) SSM Session Commands (Lab 02)

`session-manager-plugin --version`
- Verify Session Manager plugin installed.

`aws ssm start-session --target <instance-id> --region ap-southeast-1`
- Open shell session via SSM.

`exit`
- Exit SSM shell session.

## 9) IAM Verification Commands

`aws iam get-role --role-name ec2-ssm-role-lab-02`
- Verify IAM role existence.

`aws iam get-instance-profile --instance-profile-name ec2-ssm-profile-lab-02`
- Verify instance profile existence.

## 10) CloudWatch / SNS Commands (Labs 04 & 06)

`aws sns list-subscriptions-by-topic --region ap-southeast-1 --topic-arn "$(terraform output -raw sns_topic_arn)" --output table`
- Check SNS subscription status.

`aws cloudwatch describe-alarms --region ap-southeast-1 --alarm-names lab-04-high-cpu --output table`
- Check Lab 04 alarm.

`aws cloudwatch describe-alarms --region ap-southeast-1 --query "MetricAlarms[?starts_with(AlarmName, 'lab-06-')].[AlarmName,StateValue,Namespace,MetricName]" --output table`
- Check Lab 06 metric alarms.

`aws cloudwatch describe-alarms --region ap-southeast-1 --alarm-names "$(terraform output -raw composite_alarm_name)" --output table`
- Check Lab 06 composite alarm.

`aws logs describe-log-streams --region ap-southeast-1 --log-group-name "$(terraform output -raw log_group_name)" --order-by LastEventTime --descending --output table`
- Check CloudWatch Logs streams (Lab 05).

`aws logs get-log-events --region ap-southeast-1 --log-group-name "$(terraform output -raw log_group_name)" --log-stream-name "<stream-name>" --limit 20 --output text`
- Read log events from a stream.

## 11) ALB + ASG Verification (Lab 07)

`curl -I "$(terraform output -raw alb_url)"`
- Check ALB HTTP response headers.

`curl "$(terraform output -raw alb_url)"`
- Check ALB response body.

`aws autoscaling describe-auto-scaling-groups --region ap-southeast-1 --auto-scaling-group-names "$(terraform output -raw asg_name)" --query "AutoScalingGroups[0].Instances[].{Id:InstanceId,State:LifecycleState,Health:HealthStatus}" --output table`
- Check ASG instance lifecycle and health.

`aws elbv2 describe-target-health --region ap-southeast-1 --target-group-arn "$(terraform output -raw target_group_arn)" --query "TargetHealthDescriptions[].{Id:Target.Id,State:TargetHealth.State,Reason:TargetHealth.Reason}" --output table`
- Check target group health states.

## 12) User Data / Boot Debugging

`aws ec2 get-console-output --region "$REGION" --instance-id "$IID" --latest --output text | tail -n 200`
- Read latest instance console log tail.

`aws ec2 get-console-output --region "$REGION" --instance-id "$IID" --latest --output text | egrep -i "user-data|nginx|cloud-init|error|failed"`
- Filter boot log for provisioning errors.

`curl -I "http://$(terraform output -raw public_ip)"`
- Check if web server on EC2 is reachable.

## 13) Git / GitHub Commands

`git status`
- Check staged/unstaged changes.

`git add <files...>`
- Stage selected files.

`git commit -m "your message"`
- Commit staged changes.

`git push -u origin main`
- Push to GitHub remote.

`git remote -v`
- View configured remotes.

`git branch --show-current`
- Show current branch.

`git restore --staged <file>`
- Unstage accidentally staged file.

`gh repo create aws-terraform --public --source=. --remote=origin --push`
- Create and push new GitHub repository with `gh`.

`gh auth status`
- Check GitHub CLI authentication status.

`gh auth setup-git`
- Configure git credential helper via GitHub CLI.

## 14) File Setup Commands Used

`cp .gitignore lab-03-ec2-eip/.gitignore`
- Copy base `.gitignore` to new lab folder (same pattern used for other labs).
