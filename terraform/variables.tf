variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-west-1"
}

variable "instance_type" {
  description = "The type of EC2 instance to use."
  type        = string
  default     = "t3.micro"
}

variable "my_ip_cidr" {
  description = "Your public IP address for security group rules."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet."
  type        = string
}

variable "my_s3_bucket" {
  description = "The S3 bucket to use for storage."
  type        = string
}

variable "s3_artifacts_bucket" {
  description = "The S3 bucket to use for deployment artifacts."
  type        = string
}

variable "s3_cloudtrail_bucket" {
  description = "The S3 bucket to use for CloudTrail logs."
  type        = string
}