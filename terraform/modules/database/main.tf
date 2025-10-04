# Generate random DB password and store in SSM
resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"  # Exclude /, @, ", space
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/devops-assessment/${var.env}/db/password"
  type  = "SecureString"
  value = random_password.db.result
  # TODO: add KMS key_id for customer-managed encryption
}

resource "aws_db_subnet_group" "this" {
  name       = "db-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "db" {
  name        = "rds-pg-sg"
  vpc_id      = var.vpc_id
  description = "Allow Postgres from app SG"
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "pg" {
  identifier                 = "devops-assessment-pg"
  engine                     = "postgres"
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.db.id]
  
  username                   = var.db_username
  password                   = random_password.db.result
  db_name                    = var.db_name
  
  allocated_storage          = var.db_allocated_storage
  storage_encrypted          = true
  skip_final_snapshot        = true  # for dev; set false in prod
  multi_az                   = var.db_multi_az
  publicly_accessible        = false
  deletion_protection        = false # flip to true for prod
  backup_retention_period    = 7
  apply_immediately          = true
}
