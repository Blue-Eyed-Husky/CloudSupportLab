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