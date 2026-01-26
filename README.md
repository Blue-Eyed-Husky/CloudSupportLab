# My Cloud Support Lab

## Overview
This project deploys a simple, production-style AWS baseline using Terraform: 
A VPC with a public subnet, Internet Gateweay and routing, Security Group, and an EC2 instance that boots with user-data to install and start NGINX.

The goal is to practice core cloud support tasks: provisioning, connectivity (SSH/HTTP), bootstrapping, troubleshooting, and documenting failures

## Architecture
  VPC
  Public subnet
  Internet Gateway (GTW)
  Route table and Association
  Security Group (SSH restricted to my IP, HTTP open for demo)
  EC2 via ubuntu and user_data installs NGINX and writes a test page
  IAM role, SSM, CloudwWatch (planned)

Traffic flow - Internet → IGW → Route Table → Public Subnet → EC2 (NGINX on :80) 

## Repo Structure
  main.tf
  variables.tf
  outputs.tf
  user_data.sh
  terraform.tfvars.example
  .gitignore

## Prerequisites
  AWS account and IAM user/role with permissions to create VPC/EC2/SG/IGW
  AWS CLI configured 
  Terraform installed
  SSH keypair
  Visual studio code

  
