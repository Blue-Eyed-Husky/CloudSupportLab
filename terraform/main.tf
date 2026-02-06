############################################
# Networking
############################################

resource "aws_vpc" "cloud_lab_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "cloud lab vpc"
  }
}

resource "aws_subnet" "cloud_lab_subnet" {
  vpc_id                  = aws_vpc.cloud_lab_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "cloud lab subnet"
  }
}

resource "aws_internet_gateway" "cloud_lab_igw" {
  vpc_id = aws_vpc.cloud_lab_vpc.id

  tags = {
    Name = "cloud lab igw"
  }
}

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

resource "aws_route_table_association" "cloud_lab_rta" {
  subnet_id      = aws_subnet.cloud_lab_subnet.id
  route_table_id = aws_route_table.cloud_lab_rt.id
}

############################################
# Security
############################################

resource "aws_security_group" "cloud_lab_sg" {
  name        = "cloud_lab_sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = aws_vpc.cloud_lab_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################################
# CloudWatch Logs (match user_data.sh prefix)
############################################

resource "aws_cloudwatch_log_group" "cloud_lab_nginx_access" {
  name              = "/cloudlab/nginx/access"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "cloud_lab_nginx_error" {
  name              = "/cloudlab/nginx/error"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "cloud_lab_deploy" {
  name              = "/cloudlab/deploy"
  retention_in_days = 7
}

############################################
# IAM (role, instance profile, policies)
############################################

resource "aws_iam_role" "cloud_lab_instance_role" {
  name = "cloud_lab_instance_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "cloud_lab_instance_profile" {
  name = "cloud_lab_instance_profile"
  role = aws_iam_role.cloud_lab_instance_role.name
}

# SSM access (Session Manager)
resource "aws_iam_role_policy_attachment" "cloud_lab_ssm_role_attachment" {
  role       = aws_iam_role.cloud_lab_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# S3 bucket used by the instance (full access as you defined)
resource "aws_iam_policy" "cloud_lab_s3_policy" {
  name        = "cloud_lab_s3_policy"
  description = "Policy to allow EC2 instance to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.cloud_lab_bucket.arn,
          "${aws_s3_bucket.cloud_lab_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloud_lab_instance_role_attachment" {
  role       = aws_iam_role.cloud_lab_instance_role.name
  policy_arn = aws_iam_policy.cloud_lab_s3_policy.arn
}

# Allow EC2 to READ deploy artifacts from artifacts bucket (deploy/* only)
resource "aws_iam_policy" "cloud_lab_artifacts_read_policy" {
  name        = "cloud_lab_artifacts_read_policy"
  description = "Allow EC2 instance to read deployment artifacts from the artifacts bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListDeployPrefixOnly"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.cloud_lab_artifacts_bucket.arn]
        Condition = {
          StringLike = {
            "s3:prefix" = ["deploy/*"]
          }
        }
      },
      {
        Sid      = "GetDeployArtifactsOnly"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.cloud_lab_artifacts_bucket.arn}/deploy/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloud_lab_artifacts_read_attachment" {
  role       = aws_iam_role.cloud_lab_instance_role.name
  policy_arn = aws_iam_policy.cloud_lab_artifacts_read_policy.arn
}

# CloudWatch Logs permissions (works for CloudWatch Agent)
resource "aws_iam_policy" "cloud_lab_logs_policy" {
  name        = "cloud_lab_logs_policy"
  description = "Allow instance to write to CloudWatch Logs groups for nginx + deploy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        # PutLogEvents applies to LOG STREAM ARNs, so include :*
        Resource = [
          "${aws_cloudwatch_log_group.cloud_lab_nginx_access.arn}:*",
          "${aws_cloudwatch_log_group.cloud_lab_nginx_error.arn}:*",
          "${aws_cloudwatch_log_group.cloud_lab_deploy.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloud_lab_logs_attachment" {
  role       = aws_iam_role.cloud_lab_instance_role.name
  policy_arn = aws_iam_policy.cloud_lab_logs_policy.arn
}

############################################
# S3 Buckets
############################################

resource "aws_s3_bucket" "cloud_lab_bucket" {
  bucket = var.my_s3_bucket

  tags = {
    Name = "cloud lab bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "cloud_lab_bucket_pab" {
  bucket = aws_s3_bucket.cloud_lab_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "cloud_lab_artifacts_bucket" {
  bucket = var.s3_artifacts_bucket

  tags = {
    Name = "cloud lab artifacts bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "cloud_lab_artifacts_bucket_pab" {
  bucket = aws_s3_bucket.cloud_lab_artifacts_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# EC2 Instance
############################################

resource "aws_instance" "cloud_lab_instance" {
  ami                         = "ami-0290e60ec230db1e4" # (Your pinned AMI)
  instance_type               = var.instance_type
  key_name                    = "cloud_lab_key"
  subnet_id                   = aws_subnet.cloud_lab_subnet.id
  vpc_security_group_ids      = [aws_security_group.cloud_lab_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.cloud_lab_instance_profile.name
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "cloud lab instance"
  }
}
