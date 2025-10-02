# Dischem Life DevOps Assessment

Infrastructure for nginx + PostgreSQL on AWS (af-south-1).

## Plan

- VPC with public/private subnets
- Security groups (ALB, app, database)
- RDS PostgreSQL (private)
- EC2 with nginx behind ALB
- Health monitoring script

## Setup

Requires Terraform >= 1.6.0 and AWS CLI configured.