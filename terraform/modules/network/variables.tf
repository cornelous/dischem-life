variable "vpc_cidr"      { type = string }
variable "public_cidrs"  { type = list(string) }
variable "private_cidrs" { type = list(string) }
variable "region"        { type = string }
