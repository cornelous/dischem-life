output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2.name
}
