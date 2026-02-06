output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.cloud_lab_instance.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.cloud_lab_instance.public_dns
}

output "nginx_url" {
  description = "URL to access the NGINX server"
  value       = "http://${aws_instance.cloud_lab_instance.public_ip}"
}

output "ec2_id" {
  description = "EC2 instance ID"
  value       = aws_instance.cloud_lab_instance.id
}

output "instance_state" {
  description = "EC2 instance state"
  value       = aws_instance.cloud_lab_instance.instance_state
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.cloud_lab_vpc.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.cloud_lab_subnet.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.cloud_lab_sg.id
}

output "lab_bucket_name" {
  description = "Primary lab S3 bucket name"
  value       = aws_s3_bucket.cloud_lab_bucket.bucket
}

output "artifacts_bucket_name" {
  description = "Artifacts S3 bucket name"
  value       = aws_s3_bucket.cloud_lab_artifacts_bucket.bucket
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups used by the instance logging config"
  value = {
    nginx_access = aws_cloudwatch_log_group.cloud_lab_nginx_access.name
    nginx_error  = aws_cloudwatch_log_group.cloud_lab_nginx_error.name
    deploy       = aws_cloudwatch_log_group.cloud_lab_deploy.name
  }
}
