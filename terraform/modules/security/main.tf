# ALB security group - public HTTP ingress
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  vpc_id      = var.vpc_id
  description = "Allow 80 from internet"
  
  ingress { 
    from_port = 80 
    to_port = 80 
    protocol = "tcp" 
    cidr_blocks = var.alb_allow_cidrs 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# App instances - only accept traffic from ALB
resource "aws_security_group" "app" {
  name        = "app-sg"
  vpc_id      = var.vpc_id
  description = "Allow ALB to App on 80"
  
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
