# Create a VPC
resource "aws_vpc" "cloud_lab_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "cloud lab vpc"
  }
}

# Create a Subnet
resource "aws_subnet" "cloud_lab_subnet" {
  vpc_id     = aws_vpc.cloud_lab_vpc.id
  cidr_block = var.subnet_cidr

  tags = {
    Name = "cloud lab subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "cloud_lab_igw" {
  vpc_id = aws_vpc.cloud_lab_vpc.id

  tags = {
    Name = "cloud lab igw"
  }
}

# Create a Route Table
resource "aws_route_table" "cloud_lab_rt" {
  vpc_id = aws_vpc.cloud_lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud_lab_igw.id
  }

  tags = {
    Name = "cloud lab rt"
  }
}

# Associate Route Table with subnet
resource "aws_route_table_association" "cloud_lab_rta" {
  subnet_id      = aws_subnet.cloud_lab_subnet.id
  route_table_id = aws_route_table.cloud_lab_rt.id
}

# Create a Security Group
resource "aws_security_group" "cloud_lab_sg" {
  name        = "cloud_lab_sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = aws_vpc.cloud_lab_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 Instance
resource "aws_instance" "cloud_lab_instance" {
  ami           = "ami-0290e60ec230db1e4" # Amazon Ubuntu 20.04 LTS in us-west-1
  instance_type             = var.instance_type
  key_name                  = "cloud_lab_key"
  subnet_id                 = aws_subnet.cloud_lab_subnet.id
  security_groups           = [aws_security_group.cloud_lab_sg.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.cloud_lab_instance_profile.name

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "cloud lab instance"
  }
}

# Add s3 bucket to instance role"
resource "aws_s3_bucket" "cloud_lab_bucket" {
  bucket = var.my_s3_bucket

  tags = {
    Name = "cloud lab bucket"
  }
}

# Add s3 policy public access block
resource "aws_s3_bucket_public_access_block" "cloud_lab_bucket_pab" {
  bucket = aws_s3_bucket.cloud_lab_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for EC2 to access S3
resource "aws_iam_role" "cloud_lab_instance_role" {
  name = "cloud_lab_instance_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Create IAM policy to allow S3 access
resource "aws_iam_policy" "cloud_lab_s3_policy" {
  name        = "cloud_lab_s3_policy"
  description = "Policy to allow EC2 instance to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.cloud_lab_bucket.arn,
          "${aws_s3_bucket.cloud_lab_bucket.arn}/*"
        ]
      },
    ]
  })
}

# Attach IAM policy to role to allow S3 access
resource "aws_iam_role_policy_attachment" "cloud_lab_instance_role_attachment" {
  role       = aws_iam_role.cloud_lab_instance_role.name
  policy_arn = aws_iam_policy.cloud_lab_s3_policy.arn
}

# # attach iam role to ssm instance profile
# resource "aws_iam_role_policy_attachment" "cloud_lab_ssm_role_attachment" {
#   role       = aws_iam_role.cloud_lab_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# IAM instance prfile for Ec2
resource "aws_iam_instance_profile" "cloud_lab_instance_profile" {
  name = "cloud_lab_instance_profile"
  role = aws_iam_role.cloud_lab_instance_role.name
}