output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.cloud_lab_instance.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.cloud_lab_instance.public_dns
}

output "nginx_url" {
  description = "URL to access NGINX server"
  value       = "http://${aws_instance.cloud_lab_instance.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.cloud_lab_vpc.id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.cloud_lab_subnet.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.cloud_lab_sg.id
}

output "instance_state" {
  description = "EC2 Instance State"
  value       = aws_instance.cloud_lab_instance.instance_state
}

output "lab_bucket_name" {
  description = "S3 Bucket Name"
  value       = var.my_s3_bucket
}