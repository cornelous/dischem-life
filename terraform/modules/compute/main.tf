# Get current region
data "aws_region" "current" {}

# Latest Ubuntu 22.04 LTS AMI (24.04 not available in af-south-1 yet)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter { 
    name = "name" 
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] 
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM role for EC2 instances
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { 
      type = "Service" 
      identifiers = ["ec2.amazonaws.com"] 
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "nginx-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Attach SSM managed policy for Session Manager access
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Least-privilege policy to read DB password from SSM
data "aws_iam_policy_document" "getparam" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = [var.db_password_ssm_param_arn]
  }
}

resource "aws_iam_policy" "getparam" {
  name   = "get-db-pass"
  policy = data.aws_iam_policy_document.getparam.json
}

resource "aws_iam_role_policy_attachment" "getparam" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.getparam.arn
}

resource "aws_iam_instance_profile" "ec2" {
  name = "nginx-ssm-profile"
  role = aws_iam_role.ec2.name
}

# Render user data with DB connection info
locals {
  userdata = templatefile("${path.module}/../../userdata/nginx.sh", {
    region        = data.aws_region.current.id
    db_endpoint   = var.db_endpoint
    db_name       = var.db_name
    db_user       = var.db_username
    db_pass_param = var.db_password_ssm_param
  })
}

resource "aws_launch_template" "app" {
  name_prefix   = "nginx-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile { name = aws_iam_instance_profile.ec2.name }
  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(local.userdata)
}

resource "aws_lb" "alb" {
  name               = "nginx-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]
}

resource "aws_lb_target_group" "tg" {
  name     = "nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
  }
  
  # deregistration_delay = 30  # uncomment if you want faster draining
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "nginx-asg"
  desired_capacity          = 1
  max_size                  = 2
  min_size                  = 1
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_type         = "EC2"  # could use ELB for stricter checks
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  tag {
    key                 = "Name"
    value               = "nginx"
    propagate_at_launch = true
  }
}
