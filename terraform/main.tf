# Create a VPC
resource "aws_vpc" "cloud_lab_vpc" {
  cidr_block = var.vpc_cidr

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
    cidr_blocks = [var.my_ip_cidr]
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

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "cloud lab instance"
  }
}