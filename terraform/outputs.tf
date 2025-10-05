output "alb_dns_name" {
  description = "ALB DNS - open http://<dns>/ in browser"
  value       = module.compute.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint (private only)"
  value       = module.database.endpoint
}

output "ssm_instance_profile_name" {
  description = "IAM instance profile for SSM access"
  value       = module.compute.instance_profile_name
}
