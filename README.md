# AWS Production Data Platform

A production-grade cloud data platform on AWS, built with
Terraform, EKS, EMR on EKS, Apache Airflow on Kubernetes,
and a GitHub Actions CI/CD pipeline. Turns a 12-step manual
deployment into a single `./scripts/deploy.sh` command.

---

## Architecture

```
                    ┌─────────────────────────────────┐
                    │           AWS Cloud              │
                    │                                  │
                    │  ┌──────────────────────────┐   │
                    │  │      VPC (10.0.0.0/16)   │   │
                    │  │                          │   │
                    │  │  ┌───────────────────┐   │   │
                    │  │  │   EKS Cluster     │   │   │
                    │  │  │                   │   │   │
                    │  │  │  ┌─────────────┐  │   │   │
                    │  │  │  │  Airflow    │  │   │   │
                    │  │  │  │  Node Group │  │   │   │
                    │  │  │  │  (t3.medium)│  │   │   │
                    │  │  │  └──────┬──────┘  │   │   │
                    │  │  │         │ DAGs     │   │   │
                    │  │  │  ┌──────▼──────┐  │   │   │
                    │  │  │  │ EMR on EKS  │  │   │   │
                    │  │  │  │ Node Group  │  │   │   │
                    │  │  │  │ (r6i.xlarge)│  │   │   │
                    │  │  │  └──────┬──────┘  │   │   │
                    │  │  └─────────┼─────────┘   │   │
                    │  │            │ Spark jobs    │   │
                    │  │  ┌─────────▼─────────┐   │   │
                    │  │  │    S3 Data Lake    │   │   │
                    │  │  │  bronze/silver/gold│   │   │
                    │  │  └─────────┬─────────┘   │   │
                    │  │            │               │   │
                    │  │  ┌─────────▼─────────┐   │   │
                    │  │  │   Glue Data Catalog│   │   │
                    │  │  └───────────────────┘   │   │
                    │  └──────────────────────────┘   │
                    └─────────────────────────────────┘
                                    ▲
                    ┌───────────────┴───────────────┐
                    │    GitHub Actions CI/CD        │
                    │  Push to main → deploy.sh      │
                    └───────────────────────────────┘
```

---

## What Was Built

### Infrastructure (Terraform)
- **VPC** with public/private subnets across 2 AZs
- **NAT Gateway** for private subnet outbound access
- **EKS Cluster** (Kubernetes 1.29) with two managed node groups:
  - Airflow node group: `t3.medium`, autoscales 0-3
  - EMR Spark node group: `r6i.xlarge`, autoscales 0-5
- **OIDC Provider** on EKS for IRSA (no hardcoded keys)
- **S3 Data Lake** with Bronze/Silver/Gold partitions + versioning
- **Glue Data Catalog** database for metadata
- **IRSA Roles** — Airflow and EMR job execution roles with
  least-privilege S3 + Glue + EMR permissions

### Orchestration (Airflow on Kubernetes)
- Airflow migrated from Docker Compose → Helm on EKS
- KubernetesExecutor (each task runs in its own pod)
- IRSA authentication — pods get AWS permissions via
  service account annotation, zero hardcoded keys
- Custom Docker image with `apache-airflow-providers-amazon`
  pushed to ECR

### Data Pipeline (DAG)
- `spark_bronze_silver_gold` DAG
- Three sequential `EmrContainerOperator` tasks: bronze → silver → gold
- Execution mode toggle via Airflow variable —
  switch between `KubernetesPodOperator` (small jobs)
  and `EmrContainerOperator` (heavy Spark jobs)
- S3 paths and Glue database injected via Airflow Variables

### AI-Powered Cluster Monitoring (Phase 7)

Built an automated Kubernetes health monitoring system using
n8n and Groq AI that runs every 5 minutes and sends intelligent
Slack alerts with root-cause analysis and fix commands.

**n8n Workflow:**
```
Cron Trigger (every 5 min)
        ↓
K8s Log Ingestion & Metrics
        ↓
K8s Anomaly Detector (16+ failure patterns)
        ↓
Has Anomalies? ──No──→ Log Healthy Status
        │Yes
        ↓
Build Groq Prompt
        ↓
Groq AI Analysis (Llama 3.3 70B)
        ↓
Build K8s Alert Report
        ↓
Critical Alert? ──No──→ Slack Warning Alert
        │Yes
        ↓
Slack Critical Alert
```

**What It Detects:**
- CrashLoopBackOff pods
- OOMKilled containers
- Node NotReady conditions
- etcd heartbeat failures
- Pod unschedulable events
- High CPU/RAM/Disk pressure
- 16+ additional failure patterns

**What Groq AI Produces:**
- Health score (0-100)
- Root cause analysis in plain English
- Affected components list
- Exact `kubectl` fix commands
- Failure risk window estimate

**Deployed using:**
- `docker-compose.yml` in this repo (n8n self-hosted)
- n8n connected to Kubernetes API for metrics ingestion
- Groq API for LLM inference (Llama 3.3 70B)
- Slack webhooks for alert delivery

**Proof of live system:** Screenshots on
[LinkedIn](https://www.linkedin.com/in/ammadajaz) showing
a CRITICAL alert with Health Score 0/100, 21 anomalies,
OOMKills, CrashLoops, and Groq-generated fix commands.

### CI/CD (GitHub Actions + GitLab CI)
- Push to `main` triggers full deployment pipeline
- AWS OIDC authentication (recommended — no long-lived secrets)
- Pipeline: build/push ECR image → Terraform apply →
  update kubeconfig → Helm upgrade
- Manual trigger support for prod environment

### One-Click Deployment
```
./scripts/deploy.sh dev
```
Runs in order:
1. Build and push Docker image to ECR
2. `terraform apply` (provisions/updates infrastructure)
3. `aws eks update-kubeconfig` (connects kubectl to cluster)
4. `helm upgrade --install airflow` (deploys/updates Airflow)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Infrastructure as Code | Terraform 1.6+ |
| Container Orchestration | Amazon EKS (Kubernetes 1.29) |
| Big Data Processing | EMR on EKS (Spark 3.x) |
| Workflow Orchestration | Apache Airflow 2.8 on Kubernetes |
| Helm Chart | apache-airflow/airflow (official) |
| Container Registry | Amazon ECR |
| Data Lake | Amazon S3 (Bronze/Silver/Gold) |
| Data Catalog | AWS Glue |
| IAM Auth | IRSA (IAM Roles for Service Accounts) |
| CI/CD | GitHub Actions + GitLab CI |
| Cloud | AWS (us-east-1) |
| AI Monitoring | n8n + Groq AI (Llama 3.3 70B) |
| Alerting | Slack Webhooks |

---

## Repository Structure

```
.
├── infra/
│   └── terraform/
│       ├── main.tf                    # Root module wiring
│       ├── variables.tf               # Input variables
│       ├── outputs.tf                 # Output values
│       ├── versions.tf                # Provider + backend config
│       ├── backend.tf                 # S3 backend (partial config)
│       ├── env/
│       │   ├── dev.tfvars             # Dev environment values
│       │   └── backend-dev.hcl.example # Backend config template
│       ├── modules/
│       │   ├── vpc/                   # VPC, subnets, NAT, IGW
│       │   ├── eks/                   # EKS cluster, node groups, OIDC, EMR virtual cluster
│       │   ├── data-lake/             # S3 bucket + Glue database
│       │   └── iam/                   # IRSA roles (Airflow + EMR)
│       └── iam-policy-*.json          # IAM policies for deployment user
│
├── helm/
│   └── airflow/
│       └── values-dev.yaml            # Airflow Helm values for EKS dev
│
├── airflow-docker/
│   ├── Dockerfile                     # Custom Airflow image with amazon provider
│   └── dags/
│       └── spark_bronze_silver_gold.py # Bronze → Silver → Gold pipeline DAG
│
├── scripts/
│   ├── deploy.sh                      # One-click deployment entrypoint
│   ├── build_and_push_images.sh       # Build Airflow image, push to ECR
│   └── helm_deploy.sh                 # Deploy Airflow via Helm
│
├── .github/
│   └── workflows/
│       └── deploy.yml                 # GitHub Actions CI/CD pipeline
│
├── docker-compose.yml             # n8n self-hosted deployment
├── .github/
│   └── workflows/
│       └── deploy.yml             # GitHub Actions CI/CD pipeline
├── .gitlab-ci.yml                 # GitLab CI alternative
└── README.md
```

---

## Key Design Decisions

### IRSA Over Hardcoded Keys
Airflow pods authenticate to AWS via IAM Roles for Service Accounts.
The pod's Kubernetes service account is annotated with an IAM role ARN.
AWS STS validates the OIDC token and returns temporary credentials.
No access keys stored anywhere — not in Helm values, not in environment
variables, not in Kubernetes secrets.

### EMR on EKS Over Self-Managed Spark
EMR on EKS runs Spark jobs as pods on the EKS cluster without a
long-running Spark cluster. Airflow submits jobs via
`EmrContainerOperator` and EMR handles the executor lifecycle.
Spark node group scales to zero when idle — no idle cluster costs.

### Execution Mode Toggle
A single Airflow variable switches between `KubernetesPodOperator`
(lightweight jobs, runs on Airflow nodes) and `EmrContainerOperator`
(heavy Spark processing, runs on EMR nodes). No code change needed
to switch execution mode.

### Modular Terraform
Four independent modules (vpc, eks, data-lake, iam) with clean
dependency chains. Each module is independently testable. Root
`main.tf` wires outputs from vpc → eks → iam → data-lake.

### S3 Backend with DynamoDB Lock
Terraform state stored remotely in S3 with DynamoDB for state
locking. Multiple team members can run Terraform safely without
conflicting applies.

---

## Setup Guide

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | 1.6+ | Infrastructure provisioning |
| kubectl | 1.28+ | Kubernetes management |
| Helm | 3.x | Airflow deployment |
| AWS CLI | v2 | AWS operations |
| Docker | Current | Image building |

### 1. Configure AWS

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, region (us-east-1)
aws sts get-caller-identity  # Verify
```

Grant your IAM user the permissions in `infra/terraform/iam-policy-*.json`.

### 2. Create ECR Repositories

```bash
aws ecr create-repository --repository-name <your-ecr-namespace>/airflow \
  --region us-east-1
```

### 3. Configure Terraform Backend

```bash
# Create S3 bucket and DynamoDB lock table
aws s3 mb s3://<your-state-bucket> --region us-east-1
aws s3api put-bucket-versioning \
  --bucket <your-state-bucket> \
  --versioning-configuration Status=Enabled
aws dynamodb create-table \
  --table-name <your-state-lock-table> \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Copy and configure backend
cp infra/terraform/env/backend-dev.hcl.example \
   infra/terraform/env/backend-dev.hcl
# Edit backend-dev.hcl with your bucket/table names
```

### 4. Deploy

```bash
# One command deploys everything
./scripts/deploy.sh dev
```

Or step by step:

```bash
# Step 1: Provision infrastructure
cd infra/terraform
terraform init -backend-config=env/backend-dev.hcl
terraform plan -var-file=env/dev.tfvars
terraform apply -var-file=env/dev.tfvars

# Step 2: Connect kubectl
aws eks update-kubeconfig --region us-east-1 \
  --name $(terraform output -raw eks_cluster_name)
kubectl get nodes

# Step 3: Build and push image
./scripts/build_and_push_images.sh dev

# Step 4: Deploy Airflow
./scripts/helm_deploy.sh dev
```

### 5. Configure Airflow Variables

In the Airflow UI (Admin → Variables):

| Key | Value |
|-----|-------|
| `DATA_LAKE_BUCKET` | `data-platform-datalake-dev` |
| `GLUE_DATABASE` | `data_lake_dev` |
| `EMR_VIRTUAL_CLUSTER_ID` | `terraform output -raw emr_virtual_cluster_id` |
| `EMR_JOB_EXECUTION_ROLE_ARN` | `terraform output -raw emr_job_execution_role_arn` |

### 6. Cleanup

```bash
helm uninstall airflow -n airflow
cd infra/terraform
terraform destroy -var-file=env/dev.tfvars
```

---

## CI/CD

### GitHub Actions (Recommended)

Uses OIDC — no AWS access keys stored as secrets.

Required secret: `AWS_ROLE_ARN` (IAM role that GitHub Actions assumes)

Triggers:
- Push to `main` → deploys to dev
- Manual trigger with environment selector (dev/prod)

### GitLab CI (Alternative)

Uses access key secrets. Set `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY` as masked CI/CD variables.

---

## Infrastructure Outputs

After `terraform apply`:

```bash
terraform output eks_cluster_name
terraform output data_lake_bucket_name
terraform output airflow_irsa_role_arn
terraform output emr_virtual_cluster_id
terraform output emr_job_execution_role_arn
```

---

## Author

**Ammad Ajaz** — Data & Platform Engineer
- GitHub: [github.com/Ammad-10](https://github.com/Ammad-10)
- LinkedIn: [linkedin.com/in/ammadajaz](https://linkedin.com/in/ammadajaz)
- Upwork: [upwork.com/freelancers/ammadajaz](https://upwork.com/freelancers/)
