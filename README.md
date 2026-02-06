# My Cloud Support Lab

## Overview
This project simulates a production-style AWS environment built entirley with Terraform and operated using modern cloud support practices: 

The environment includes a VPC with a public subnet, Internet Gateweay and routing, Security Group with restricted SSH access, and an EC2 instance bootstrapped with user-data to install and run NGINX. The instance is managed via AWS Systems Manager usign IAM roles - No SSH required for day-to-day operations.

A CI/CD piepline built with GitHub Actions performs artifact-based depoyments using S3 + SSM Run Command, closely mirroring real-world cloud operations workflows.

The goal of this project is to practice real cloud support, operations, and DevOps fundamentals, including infrastructure provisioning, secure access, automated deployments, observability, and incident troubleshooting.

## Architecture
Internet → IGW → Route Table → Public Subnet → EC2 (NGINX :80)
↑
SSM Agent
↑
GitHub Actions → Build Artifact → Private S3 Bucket → SSM Run Command → EC2 Deploy

Key concepts demonstrated: 
- Infrastructure as Code (Terraform)
- System manger instead of SSH
- IAM roles and least-privilege access
- Artifact-based CI/CD deployment
- IAM-controlled server access
- Troubleshooting via incident documentation
- CloudWatch and CloudTrail for observability and auditing
- Separation of control plane (SSM/IAM) and data plane (application traffic)

## Repo Structure
- terraform/ - infrastructure as code
- incidents/ - real failure scenarios and root cause analysis
- site/ - static website served by nginx
- .github/workflows/ - CI/CD pipeline deploying via S3 + SSM

## CI/CD Deployment Flow
- git push
↓
- GitHub Actions packages site into artifact
↓
- Artifact uploaded to private S3 bucket
↓
- SSM Run Command triggers deploy on EC2
↓
- EC2 downloads artifact and updates nginx root

No SSH. No git on server. Fully IAM-controlled.

## Incident Scenarios
This project includes multiple documented failure scenarios to simulate real cloud support incidents including: 
- SSH connectively failure (security group misconfiguration)
- HTTP access failure
- NGINX service failure
- IAM policy and permission errors
- CI/CD deployment failure
- Observability and logging validation issues

## Prerequisites
  AWS account and IAM user/role with permissions to create VPC/EC2/SG/IGW
  AWS CLI configured 
  Terraform installed
  SSH keypair
  Visual studio code
  AWS CLI
  GitHub Actions secrets configured
  SSM-enabled EC2 instance role
  
