# main.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # CẤU HÌNH S3 BACKEND & DYNAMODB LOCKING (Sau khi đã tạo ở Bước 0)
  backend "s3" {
    bucket         = "cdo-g7-tydinhvan2062002-unique"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cdo-g7-terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ==================== STEP 1: VPC MODULE (PUBLIC & PRIVATE SUBNETS) ====================
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "nhom7-production-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"] 
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = false 
  enable_vpn_gateway = false

  tags = { Environment = "Production", Project = "1-Click-AWS" }
}

# ==================== STEP 5: SECURITY GROUPS (LEAST PRIVILEGE) ====================

# Security Group cho Web Server (EC2) - Chỉ mở cổng cần thiết
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Mở cổng HTTP cho cả thế giới
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Mở SSH để quản trị (Có thể bóp lại bằng IP cá nhân)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group cho Database (RDS) - Chỉ nhận traffic  từ EC2
resource "aws_security_group" "db_sg" {
  name        = "database-rds-sg"
  description = "Allow MySQL traffic strictly from Web EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # Chặn tuyệt đối bên ngoài, chỉ nhận từ EC2 Web
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==================== STEP 2: EC2 INSTANCE (WEB SERVER IN PUBLIC SUBNET) ====================
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4000
}

resource "aws_key_pair" "generated_key" {
  key_name   = "nhom7-ec2-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.ec2_key.private_key_pem
  filename = "${path.module}/ec2_private_key.pem"
}

resource "aws_instance" "web" {
  ami                    = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 tại us-east-1
  instance_type          = "t3.micro"               # Tiết kiệm chi phí Free Tier
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.generated_key.key_name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Nhom 7 - Web Server deployed successfully via Terraform 1-Click!</h1>" > /var/www/html/index.html
              EOF

  tags = { Name = "nhom7-web-server" }
}

# ==================== STEP 3: RDS MYSQL (IN PRIVATE SUBNET) ====================
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "nhom7-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets
  tags       = { Name = "My DB subnet group" }
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  max_allocated_storage  = 100
  db_name                = var.db_name
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" # Phù hợp cho Lab/Free Tier
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = { Name = "nhom7-mysql-rds" }
}

# ==================== STEP 4: S3 BUCKET FOR STATIC ASSETS ====================
resource "aws_s3_bucket" "assets" {
  bucket        = "cdo-g7-assets-buckecttydinhvan2062002-unique" 
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "assets_public_block" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}