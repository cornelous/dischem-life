# Dischem Life DevOps Assessment

Infrastructure for nginx + PostgreSQL on AWS (af-south-1).

## What's deployed

- VPC: 2 public + 2 private subnets across 2 AZs
- IGW + NAT Gateway
- ALB (public) → ASG with nginx instances (private)
- RDS PostgreSQL in private subnets, encrypted
- SSM for instance access (no SSH)
- Health check script runs every minute via systemd timer

## Usage

```bash
cd terraform
terraform init

terraform workspace new dev || terraform workspace select dev

terraform plan -var-file=../tfvars/dev.auto.tfvars
terraform apply -var-file=../tfvars/dev.auto.tfvars

# Get ALB DNS:
terraform output alb_dns_name

Tear down:

bash
terraform destroy -var-file=../tfvars/dev.auto.tfvars

Notes
Using local state for now
Region: af-south-1 (NAT Gateway is expensive here)
DB password stored in SSM Parameter Store