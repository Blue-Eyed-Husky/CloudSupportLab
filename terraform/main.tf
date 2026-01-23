# Create a VPC
resource "aws_vpc" "cloud_lab_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "cloud_lab_vpc"
  }
}

# Create a Subnet
resource "aws_subnet" "cloud_lab_subnet" {
  vpc_id            = aws_vpc.cloud_lab_vpc.id
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "cloud_lab_subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "cloud_lab_igw" {
  vpc_id = aws_vpc.cloud_lab_vpc.id

  tags = {
    Name = "cloud_lab_igw"
  }
}