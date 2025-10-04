output "endpoint" {
  value = aws_db_instance.pg.address
}

output "db_password_ssm_param" {
  value = aws_ssm_parameter.db_password.name
}

output "db_password_ssm_param_arn" {
  value = aws_ssm_parameter.db_password.arn
}
