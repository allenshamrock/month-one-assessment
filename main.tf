provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "techcorp-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = { Name = "techcorp-igw" }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Public Subnets (2)
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "techcorp-public-subnet-${count.index + 1}"
  }
}

# Private Subnets (2)
resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "techcorp-private-subnet-${count.index + 1}"
  }
}

# Elastic IPs for NAT gateways
resource "aws_eip" "nat_eip" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "techcorp-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateways (1 per AZ)
resource "aws_nat_gateway" "nat_gw" {
  count         = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name = "techcorp-nat-gw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "techcorp-public-rt" }
}

# Associate public subnets with public RT
resource "aws_route_table_association" "public" {
  count         = 2
  subnet_id     = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per NAT gateway/AZ)
resource "aws_route_table" "private" {
  count  = length(aws_nat_gateway.nat_gw)
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "techcorp-private-rt-${count.index + 1}"
  }
}

# Associate private subnets with private RTs (1:1)
resource "aws_route_table_association" "private" {
  count         = 2
  subnet_id     = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security groups
resource "aws_security_group" "bastion_sg"{
  name        = "bastion_sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH from my ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Techcorp-bastion-sg" }
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from bastion"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.bastion_sg.id] # allow SG -> SG
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-web-sg" }
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Security group for database server"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "PostgreSQL from web servers"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-db-sg" }
}

# Keypair generation and local private key file
resource "tls_private_key" "techcorp_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "techcorp_key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.techcorp_key.public_key_openssh
}

resource "local_file" "private_key_file" {
  content         = tls_private_key.techcorp_key.private_key_pem
  filename        = "${path.module}/techcorp_key.pem"
  file_permission = "0400"
}

# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion host
resource "aws_instance" "bastion_host" {
  ami                       = data.aws_ami.amazon_linux_2.id
  instance_type             = var.bastion_instance_type
  subnet_id                 = aws_subnet.public_subnet[0].id
  key_name                  = aws_key_pair.techcorp_key_pair.key_name
  vpc_security_group_ids    = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = { Name = "techcorp-bastion" }
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion_host.id
  domain   = "vpc"

  tags = { Name = "techcorp-bastion-eip" }

  depends_on = [aws_internet_gateway.igw]
}

# Web servers in private subnets
resource "aws_instance" "web_server_1" {
  ami                     = data.aws_ami.amazon_linux_2.id
  instance_type           = var.web_instance_type
  subnet_id               = aws_subnet.private_subnet[0].id
  key_name                = aws_key_pair.techcorp_key_pair.key_name
  vpc_security_group_ids  = [aws_security_group.web_sg.id]
  user_data               = file("${path.module}/user_data/web_server_setup.sh")

  tags = { Name = "techcorp-web-server-1" }

  depends_on = [aws_nat_gateway.nat_gw]
}

resource "aws_instance" "web_server_2" {
  ami                     = data.aws_ami.amazon_linux_2.id
  instance_type           = var.web_instance_type
  subnet_id               = aws_subnet.private_subnet[1].id
  key_name                = aws_key_pair.techcorp_key_pair.key_name
  vpc_security_group_ids  = [aws_security_group.web_sg.id]
  user_data               = file("${path.module}/user_data/web_server_setup.sh")

  tags = { Name = "techcorp-web-server-2" }

  depends_on = [aws_nat_gateway.nat_gw]
}

# DB server in first private subnet (adjust if desired)
resource "aws_instance" "db_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.db_instance_type
  subnet_id              = aws_subnet.private_subnet[0].id
  key_name               = aws_key_pair.techcorp_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  user_data              = file("${path.module}/user_data/db_server_setup.sh")

  tags = { Name = "techcorp-db-server" }

  depends_on = [aws_nat_gateway.nat_gw]
}

# ALB and target group
resource "aws_lb" "web_lb" {
  name               = "techcorp-web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]

  tags = { Name = "techcorp-web-lb" }
}

resource "aws_lb_target_group" "web_tg" {
  name    = "techcorp-web-tg"
  port    = 80
  protocol = "HTTP"
  vpc_id  = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
    enabled             = true
  }

  tags = { Name = "techcorp-web-tg" }
}

resource "aws_lb_target_group_attachment" "web_tg_attachment_1" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_tg_attachment_2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}

resource "aws_lb_listener" "web_lb_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
