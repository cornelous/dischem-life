variable "vpc_id"                { type = string }
variable "public_subnet_ids"     { type = list(string) }
variable "private_subnet_ids"    { type = list(string) }
variable "alb_sg_id"             { type = string }
variable "app_sg_id"             { type = string }
variable "instance_type"         { type = string }
variable "key_pair_name" { 
  type    = string 
  default = null 
  # Not currently used; SSM Session Manager is the access method
}
variable "db_endpoint"           { type = string }
variable "db_name"               { type = string }
variable "db_username"           { type = string }
variable "db_password_ssm_param" { type = string }
variable "db_password_ssm_param_arn" { type = string }
variable "env"                   { type = string }
