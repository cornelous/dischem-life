# General config
variable "region" {
  type    = string
  default = "af-south-1"
}
variable "env" {
  type    = string
  default = "dev"
}
variable "owner" {
  type    = string
  default = "clive"
}

# Network
variable "vpc_cidr" {
  type    = string
  default = "10.16.0.0/16"
}
variable "public_cidrs" {
  type    = list(string)
  default = ["10.16.0.0/24", "10.16.1.0/24"]
}
variable "private_cidrs" {
  type    = list(string)
  default = ["10.16.10.0/24", "10.16.11.0/24"]
}

# Compute
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "key_pair_name" {
  type    = string
  default = null
  # Not currently used; SSM Session Manager is the access method
}

variable "alb_allow_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"] # lock this down for prod
}

# Database
variable "db_name" {
  type    = string
  default = "appdb"
}
variable "db_username" {
  type    = string
  default = "appuser"
}
variable "db_engine_version" {
  type    = string
  default = "15"
}
variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro" # ARM-based, cheaper
}
variable "db_allocated_storage" {
  type    = number
  default = 20
}
variable "db_multi_az" {
  type    = bool
  default = false # single AZ for dev
}
