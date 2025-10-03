# Dischem Life DevOps Assessment

Infrastructure for nginx + PostgreSQL on AWS (af-south-1).

## Progress

✅ VPC with public/private subnets across 2 AZs
✅ Security groups (ALB, app)
🚧 Working on database and compute modules

## Current Structure

- Network module: VPC, IGW, NAT, route tables, SSM VPC endpoints
- Security module: ALB and app security groups
- Using af-south-1 region

## Usage

```bash
cd terraform
terraform init
terraform plan -var-file=../tfvars/dev.auto.tfvars