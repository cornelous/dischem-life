# Dischem Life DevOps Assessment

Infrastructure for nginx + PostgreSQL on AWS (af-south-1 / Cape Town).

## What's here

- VPC: 2 public + 2 private subnets across 2 AZs
- IGW + NAT Gateway (watch the costs in CPT region, NAT is pricey)
- ALB (public) → ASG with nginx instances (private, Ubuntu 22.04)
- RDS PostgreSQL in private subnets, encrypted at rest
- SSM for instance access (no SSH keys), DB password in Parameter Store
- Health check script runs every minute via systemd timer, updates the nginx homepage

Region is hardcoded to `af-south-1` in tfvars. AZ selection uses the first two available zones for your account (AWS maps letters differently per account, so can't hardcode a/b).

## Usage

```bash
cd terraform
terraform init

# Using workspaces for envs (optional but cleaner)
terraform workspace new dev || terraform workspace select dev

terraform plan -var-file=../tfvars/dev.auto.tfvars
terraform apply -var-file=../tfvars/dev.auto.tfvars

# Outputs:
# - alb_dns_name: http://<dns>/
# - rds_endpoint: private only, app can reach it

Tear down:

bash
terraform destroy -var-file=../tfvars/dev.auto.tfvars

State backend
Currently using local state. For team use, uncomment the S3 backend in 
terraform/backend.tf
 and run terraform init -migrate-state. You'll need to create the bucket + DynamoDB table first.

Makefile
There's a Makefile in the root if you want shortcuts:

bash
make init
make plan
make apply
make destroy
Security bits
No SSH access, use SSM Session Manager instead (VPC endpoints configured)
DB password is random, stored in SSM Parameter Store (SecureString), not exposed in outputs
RDS is private-only, security group locked to app instances
ALB is HTTP-only on port 80 for now (TODO: add ACM cert + HTTPS listener)
Default alb_allow_cidrs is 0.0.0.0/0 for demo; lock it down in tfvars for prod
Known issues / TODOs
Health script doesn't handle DB connection timeout gracefully (psql hangs if RDS is slow to start)
Should add CloudWatch alarms for ALB 5xx and ASG health
Consider adding tflint/checkov to CI
key_pair_name variable exists but isn't wired up (leftover from earlier iteration)