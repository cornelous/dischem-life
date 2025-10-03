# Grab available AZs for the region
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.region]
  }
}

locals {
  # Use first 2 AZs - AWS maps letters per account so can't hardcode af-south-1a/1b
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # needed for RDS endpoints
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_subnet" "public" {
  for_each = { for i, cidr in var.public_cidrs : i => { cidr = cidr, az = local.azs[i] } }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}
resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Single NAT in first public subnet (cost tradeoff vs HA)
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  subnet_id     = values(aws_subnet.public)[0].id
  allocation_id = aws_eip.nat.id
  # TODO: for prod, consider NAT per AZ for HA
}

resource "aws_subnet" "private" {
  for_each = { for i, cidr in var.private_cidrs : i => { cidr = cidr, az = local.azs[i] } }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# VPC endpoints for SSM - lets us manage instances without SSH or public IPs
locals {
  ep_services = [
    "com.amazonaws.${var.region}.ssm",
    "com.amazonaws.${var.region}.ssmmessages",
    "com.amazonaws.${var.region}.ec2messages"
  ]
}

resource "aws_security_group" "endpoints" {
  name        = "vpce"
  description = "Interface endpoint SG"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { 
    from_port = 443 
    to_port = 443 
    protocol = "tcp" 
    cidr_blocks = [for s in var.private_cidrs : s] 
  }
}

resource "aws_vpc_endpoint" "interfaces" {
  for_each            = toset(local.ep_services)
  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.endpoints.id]
  subnet_ids          = [for s in aws_subnet.private : s.id]
}
