# My Cloud Support Lab

## Overview
This project simulates a production-style AWS environment built entirley with Terraform and operated using modern cloud support practices: 

It includes a VPC with a public subnet, Internet Gateweay and routing, Security Group with restricted SSH and HTTP access, and an EC2 instance that's bootstrapped with user-data to install and start NGINX. It has IAM role with SSM access (no SSH required for management), CI/CD pipeline using GitHub Actions and Artifact-based deployment using S3 + SSM Run Command.

The goal is to practice real-world cloud support and DevOps workflows: provisioning, connectivity, bootstrapping, remote management, CI/CD, and incident troubleshooting.

## Architecture
Internet → IGW → Route Table → Public Subnet → EC2 (NGINX :80)
↑
SSM Agent
↑
GitHub Actions → S3 Artifact → SSM Run Command → EC2 Deploy

Key concepts demonstrated: 
  Infrastructure as Code (Terraform)
  System manger instead of SSH
  Artifact-based CI/CD deployment
  IAM-controlled server access
  Troubleshooting via incident documentation

## Repo Structure
  terraform/ - infrastructure as code
  incidents/ - real failure scenarios and root cause analysis
  site/ - static website served by nginx
  .github/workflows/ - CI/CD pipeline deploying via S3 + SSM

## CI/Cd Deployment Flow
git push
↓
GitHub Actions packages site into artifact
↓
Artifact uploaded to private S3 bucket
↓
SSM Run Command triggers deploy on EC2
↓
EC2 downloads artifact and updates nginx root

No SSH. No git on server. Fully IAM-controlled.

## Prerequisites
  AWS account and IAM user/role with permissions to create VPC/EC2/SG/IGW
  AWS CLI configured 
  Terraform installed
  SSH keypair
  Visual studio code
  AWS CLI
  GitHub Actions secrets configured
  SSM-enabled EC2 instance role
  
