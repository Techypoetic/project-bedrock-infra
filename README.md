# Project Bedrock - InnovateMart EKS Deployment
## Overview
Production-grade Amazon EKS cluster deployment with the AWS Retail Store Sample Application.
**Student:** Barakat  
**Student ID:** alt-soe-025-1162  
**Course:** AltSchool Africa Third Semester Capstone  


## Quick Start
```bash
# 1. Setup Terraform backend
./scripts/setup-backend.sh
# 2. Initialize Terraform
cd terraform/
terraform init
# 3. Deploy infrastructure
terraform plan
terraform apply
```
## Repository Structure
```
project-bedrock/
├── .github/workflows/    # CI/CD pipelines
├── terraform/            # Infrastructure as Code
│   └── modules/          # Reusable Terraform modules
├── kubernetes/           # Kubernetes manifests
├── lambda/               # Lambda function code
├── scripts/              # Helper scripts
└── docs/                 # Documentation
```
