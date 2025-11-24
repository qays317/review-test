# 🚀 AWS Multi-Region WordPress Disaster Recovery Architecture


[![Deploy Multi-Region Infrastructure](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/deploy.yml/badge.svg)](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/deploy.yml)

[![Destroy Multi-Region Infrastructure](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/destroy.yml/badge.svg)](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/destroy.yml)


**Production-Grade • Highly Available • Fault-Tolerant • Terraform & AWS**

This repository delivers a **real-world enterprise disaster recovery design** for running WordPress across **two AWS regions** using a fully automated, highly available, self-healing architecture.

All infrastructure is 100% managed using **Terraform**, following AWS **Well-Architected best practices**.

---

# 📘 **Table of Contents**

* [Architecture Overview](#architecture-overview)
* [Key Features](#key-features)
* [Design Principles](#design-principles)
* [Technology Stack](#technology-stack)
* [Infrastructure Components](#infrastructure-components)
* [Failover Strategy](#failover-strategy)
* [Terraform Structure](#terraform-structure)
* [Deployment & Destroy Workflow](#deployment-and-destroy-workflow)
* [DR Failover Guide](#dr-failover-guide)
* [Security Best Practices](#security-best-practices)
* [Cost Optimization](#cost-optimization)
* [License](#license)

---

# 🏗 **Architecture Overview**

This project deploys a multi-region, production-grade WordPress platform using:

* **Primary Region:** `us-east-1`
* **DR Region:** `ca-central-1`
* **Global routing:** **CloudFront + Route 53**
* **Containers:** ECS Fargate
* **Database:** RDS MySQL with cross-region read-replica
* **Media:** S3 + CloudFront
* **Failover:** CloudFront Origin Groups (primary ALB → DR ALB)

---

## 🏗 Multi-Region Architecture (ASCII Diagram)

                    ┌────────────────────┐
                    │     Route 53       │
                    └─────────┬──────────┘
                              │
                              ▼
                    ┌────────────────────┐
                    │    CloudFront      │
                    │  Origin Groups     │
                    └─────────┬──────────┘
               (HTTP errors)  │    (Normal)
               Failover       │
        ┌─────────────────────┴─────────────────────┐
        │                                           │
        ▼                                           ▼
┌──────────────────┐                     ┌──────────────────┐
│   ALB (Primary)  │                     │    ALB (DR)      │
│   us-east-1      │   <-- fallback -->  │  ca-central-1    │
└─────────┬────────┘                     └─────────┬────────┘
          │                                          │
          ▼                                          ▼
 ┌──────────────────┐                        ┌──────────────────┐
 │ ECS Fargate (2)  │                        │ ECS Fargate (0*) │
 │ WordPress Tasks  │                        │ Warm Standby     │
 └──────────────────┘                        └──────────────────┘
          │                                          │
          ▼                                          ▼
┌──────────────────┐                      ┌──────────────────┐
│ RDS MySQL        │  Replica            │ RDS Read Replica  │
│ Primary (Writer) │ ───────────────────▶│ DR Region         │
└──────────────────┘                      └──────────────────┘

                Media Failover (Automatic)
        ┌────────────────────┐      ┌────────────────────┐
        │   S3 Primary       │◀────▶│     S3 DR           │
        └────────────────────┘      └────────────────────┘

---

# ⭐ **Key Features**

### 🟢 High Availability & Automated Failover

* Multi-region ECS + ALB
* Cross-region database replication
* CloudFront origin failover with no DNS delay

### 🌍 Global Content Delivery

* S3 + CloudFront for media
* Uploads served from nearest edge location

### 🔒 Hardened Security

* TLS everywhere
* Secrets in AWS Secrets Manager
* IAM-role access for WordPress S3 integration
* Private subnets, VPC endpoints, strict SGs

### ⚙️ Fully Automated with Terraform

* Modular structure
* Remote state per environment
* Zero manual configuration

---

# 📐 **Design Principles**

| AWS Well-Architected Pillar | Implementation                                         |
| --------------------------- | ------------------------------------------------------ |
| **Reliability**             | Multi-region, auto failover, RDS replica               |
| **Security**                | HTTPS, IAM roles, secrets manager, least-privilege SGs |
| **Performance**             | CloudFront CDN, S3 media, Fargate                      |
| **Cost-Optimization**       | Warm standby DR, endpoints to reduce NAT traffic       |
| **Operational Excellence**  | Full IaC, zero manual provisioning                     |

---

# 🔧 **Technology Stack**

### **AWS Services**

* ECS Fargate
* RDS MySQL (Multi-Region)
* S3 (Primary + DR)
* CloudFront CDN
* ALB
* Route 53
* Secrets Manager
* VPC + Endpoints
* CloudWatch + Logs
* ACM (provided or auto-generated)

### **Application Stack**

* WordPress
* WP-CLI
* Amazon S3 / CloudFront plugin
* Hardened `wp-config.php`
* Custom Docker image

---

# 🧱 **Infrastructure Components**

### 🟦 **1. ECS Fargate WordPress**

* Stateless containers
* Auto-healing
* No EC2 management
* Custom Dockerfile:

  * WP installed via WP-CLI
  * S3 plugin auto-configured
  * Admin URL rewriting
  * HTTPS detection (for CloudFront/ALB)

---

### 🟩 **2. Application Load Balancer**

* HTTPS termination
* Health checks used by CloudFront failover
* Admin subdomain bypasses CloudFront and routes directly to the ALB

---

### 🟥 **3. CloudFront Distribution**

* Two origin groups:

  1. **ALB Primary → ALB DR**
  2. **S3 Primary → S3 DR**
* Default: application traffic
* Ordered: WordPress media uploads
* Full automatic failover
* TLS enabled using ACM

---

### 🟨 **4. RDS MySQL**

* Primary RDS
* DR region read-replica
* Manual promotion during primary region failure

---

### 🟫 **5. S3 Media Storage**

* Two buckets (Primary + DR)
* CloudFront reads from both
* WordPress writes to the primary bucket
* IAM roles remove need for S3 keys

---

### 🟪 **6. VPC + Networking**

* Private ECS subnets
* Public ALB subnets
* NAT Gateway minimized
* VPC Endpoints:

  * S3
  * ECR
  * Logs
  * Secrets Manager
  * CloudWatch

* Each region has its own isolated VPC to ensure true regional independence.

---

# 🌐 **Failover Strategy**

## **1. Application Failover (Fully Automatic)**

CloudFront Origin Group:

```
Primary ALB → DR ALB
```

Triggers failover on:

* 5xx errors
* Timeout
* ALB unreachable
* Security group or NACL issues

**Users experience zero downtime**.

---

## **2. Media Failover**

CloudFront S3 Origin Group:

```
Primary S3 → DR S3
```

Read failover is automatic.
Write failover is controlled at ECS task-level.

---

## **3. Database Failover (RDS → DR Region)**

### Default (manual):

* Amazon RDS MySQL (Primary Region)
* Cross-Region Read Replica (DR Region)
* AWS Secrets Manager per region (Primary secret, DR secret)
* ECS Tasks in each region automatically read the correct secret

---

## **4. ECS Failover**

### **Primary Region**
- Runs full production ECS service (ex: 2 tasks)
- Serves all user traffic under normal conditions

### **DR Region (Warm Standby)**
- ECS service is fully deployed but scaled down to 0 tasks.
- This keeps costs minimal while ensuring the infrastructure is ready.

### **Failover Process**
When the primary region becomes unavailable:

1. **CloudFront automatically fails over** to the DR ALB.
2. The DR ECS service is **manually scaled** (or via automation) from 0 to 2 tasks.
3. DR tasks start, register with the DR target group, and immediately begin serving traffic.

This architecture follows AWS Warm Standby DR pattern — a cost-efficient model where the secondary region remains ready but scaled down until failover.


---

# 📁 **Terraform Structure**

```bash
aws-disaster-recovery/
│
├── environments/
│   ├── global/
│   │   ├── iam/
│   │   ├── oac/  
│   │   ├── cdn_dns/
│   ├── primary/
│   │   ├── network_rds/
│   │   ├── s3/
│   │   ├── alb/
│   │   ├── ecs/     
│   └── dr/
│       ├── network/
│       ├── read_replica_rds/
│       ├── s3/
│       ├── alb/
│       └── ecs/
├── modules/
│   ├── acm/
│   ├── alb/
│   ├── cdn/
│   ├── ecs/
│   ├── iam/
│   ├── rds/
│   ├── s3/
│   ├── sg/
│   └── vpc
└── scripts/
    └── deployment-automation-scripts/
    │   ├── config.sh
    │   ├── deploy.sh
    │   ├── destroy.sh
    │   └── pull-docker-hub-to-ecr.sh
    └── runtime/
        ├── primary-ecr-image-uri
        └── dr-ecr-image-uri
 
   
```

This structure prevents dependency cycles and allows independent region deployments.

---

# 🚀 **Deployment & Destroy Workflow**

This project includes fully automated deployment and teardown scripts located in:
scripts/deployment-automation-scripts/

These scripts deploy stacks in the correct order:

1. **Primary Region** (by default: us-east-1)  
2. **DR Region** (by default: ca-central-1)  
3. **Global Stack** (CloudFront + Route 53)


They also handle:

- ECR image mirroring
- Terraform variable injection
- Runtime metadata
- State validation

## ⚙️ Prerequisite (Required Before Any Deployment): 

Before running any deployment method (manual or GitHub Actions), two prerequisites must be completed.

### 1.Bootstrap: GitHub Actions OIDC Role (One-Time Setup)

This project uses GitHub OIDC -> AWS IAM for secure, keyless CI/CD authentication.
This bootstrap stack must be deployed once before using GitHub Actions:

To use OIDC, the IAM role and trust relationship must be created manually once.

Step A - Authenticate locally to AWS
authenticate using either:
- option 1: AWS CLI profile
```bash
aws configure
```
- option 2: Environment variables
```bash
export AWS_ACCESS_KEY_ID=xxxx
export AWS_SECRET_ACCESS_KEY=xxxx
export AWS_DEFAULT_REGION=us-east-1
```

Step B - Deploy the Bootstrap Stack
from the project roo, run:
```bash
terraform -chdir=environments/bootstrap init
terraform -chdir=environments/bootstrap apply 
``` 
This stack creates:
|              Resource                      |                            Purpose                                   |
| ------------------------------------------ | -------------------------------------------------------------------- |
| AWS IAM OpenID Connect Provider (GitHub)   | Allow GitHub Actions to authenticate to AWS                          |
| GitHub Actions IAM role                    | This is assumed by the deploy/destroy workflows                      |
| Trust policy restricted to the repository  | security-hardening: only our repository can use this role            |
| AdministratorAccess policy                 | Full deploy/destroy capabilities (reviewer may restrict this later)  |

After this role is created, GitHub Actions can deploy the entire infrastructure with zero AWS keys. After bootstrap, no AWS credentials are needed anywhere in the project.

### 2.Configure config.sh Before Deployment

Before running:
* deploy.sh
* destroy.sh
* GitHub Actions workflows

The user must configure:
scripts/deployment-automation-scripts/config.sh

This file contains all environment-specific parameters:

✔ Required fields inside config.sh

| Variable                | Purpose                                     |
|-------------------------|---------------------------------------------|
| PRIMARY_REGION          | ex: us-east-1                               |
| DR_REGION               | ex: ca-central-1                            |
| AWS_ACCOUNT_ID          | User’s AWS account ID                       |
| DOCKERHUB_IMAGE         | Docker Hub image used for ECR mirroring     |
| ECR_REPO_NAME           | Name of ECR repository                      |
| PRIMARY_ENV_NAME        | Name of primary Terraform stack             |
| DR_ENV_NAME             | Name of DR Terraform stack                  |
| TF_STATE_BUCKET_NAME    | Name of S3 remote state bucket              |  
| TF_STATE_BUCKET_REGION  | Region of S3 remote state bucket            |


This design ensures:
- No AWS region values are hard-coded
- GitHub Actions stays generic
- Reviewers can deploy the entire system only by editing config.sh

## 📦 CI/CD (GitHub Actions) Deployment Workflows

This project provides two manually-triggered GitHub Actions workflows located in:
.github/workflows/

- Deploy Workflow — Deploys the entire multi-region AWS infrastructure
- Destroy Workflow — Tears down all resources in the correct dependency order

They simply execute the existing deployment scripts:
scripts/deployment-automation-scripts/deploy.sh
scripts/deployment-automation-scripts/destroy.sh

## 📦 Deploy the Full Multi-Region Architecture

From the project root, run:
./scripts/deployment-automation-scripts/deploy.sh

✔ What this script does

It automatically performs:

- Validates AWS CLI authentication
- Mirrors WordPress Docker image to ECR (primary + DR)
- Deploys Primary Region Terraform stack
- Deploys DR Region Terraform stack
- Deploys Global Stack (CloudFront, Route53, ACM validation)

It internally calls the helper script:
./scripts/deployment-automation-scripts/push-docker-hub-to-ecr.sh <aws-region> <environment>

This helper script:

Pulls the image from Docker Hub
Creates the ECR repo (if it doesn’t exist)
Tags & pushes the image to:
<account>.dkr.ecr.<region>.amazonaws.com/ecs-wordpress-app:<tag>
Saves the ECR image URI at:
scripts/deployment-automation-scripts/runtime/<environment>-ecr-image-uri

This makes the deployment process fully automated and region-agnostic.

## 💣 Destroy the Entire Infrastructure

To remove all resources safely, run:
./scripts/deployment-automation-scripts/destroy.sh

✔ What this script does

Destroys Global Stack
Destroys DR Region
Destroys Primary Region
Cleans runtime metadata in:
scripts/deployment-automation-scripts/runtime/

Use this only when you want to remove all AWS resources.

---

# 🆘 **DR Failover Guide**

### Automatic:

✔ CloudFront routes traffic to DR ALB
✔ S3 read failover
✔ WordPress stays online

### Manual:

1. Promote DR RDS replica
2. Scale ECS tasks in DR region
3. Update S3 write origin (only if primary S3 is down)
4. Post-incident: re-establish replication. After the primary region is restored, the old primary RDS instance must be replaced and a new cross-region read replica must be created to re-establish multi-region replication.

---

# 🔐 **Security Best Practices Used**

* TLS 1.2+ enforced
* HTTPS for admin + frontend
* Private database
* Security Groups use least privilege
* Secrets stored in Secrets Manager
* IAM roles used instead of access keys
* S3 buckets private (CloudFront handles access)
* Apache SSL disabled inside container (ALB handles TLS)

---

# 💰 **Cost Optimization Techniques**

| Component  | Optimization                                  |
| ---------- | --------------------------------------------- |
| ECS        | 1-task warm standby DR cluster                |
| RDS        | Single read-replica instead of Multi-AZ + CRR |
| NAT        | VPC endpoints reduce NAT usage                |
| CloudFront | PriceClass for region control                 |
| S3         | Only one write bucket (primary)               |

---

# 📄 **License**

This project is open for personal and educational use.

---
