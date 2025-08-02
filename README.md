# MLOps Infrastructure as Code (IAC)

## Overview
This repository contains the Infrastructure as Code (IAC) components for deploying and managing the MLOps pipeline infrastructure. The infrastructure is split into two main components: **Terraform** for AWS cloud resources and **Kubernetes** for containerized workload orchestration.

---

## 🏗️ Infrastructure Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                           │
│  ┌─────────────────────────────────────────────────────────┤
│  │                    VPC (10.0.0.0/16)                   │
│  │  ┌──────────────────┐  ┌──────────────────┐           │
│  │  │   Public Subnet  │  │  Private Subnet  │           │
│  │  │   10.0.1.0/24    │  │   10.0.2.0/24    │           │
│  │  │                  │  │                  │           │
│  │  │  ┌─────────────┐ │  │                  │           │
│  │  │  │ EC2 Instance│ │  │                  │           │
│  │  │  │ (t3.large)  │ │  │                  │           │
│  │  │  │             │ │  │                  │           │
│  │  │  │ Kubernetes  │ │  │                  │           │
│  │  │  │ Cluster     │ │  │                  │           │
│  │  │  └─────────────┘ │  │                  │           │
│  │  └──────────────────┘  └──────────────────┘           │
│  └─────────────────────────────────────────────────────────┤
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Terraform Infrastructure

### Components Overview

#### 1. Core Network Infrastructure
- **VPC**: Isolated network environment (`10.0.0.0/16`)
- **Subnets**: Public and private subnets across multiple AZs
- **Internet Gateway**: Enables internet access for public resources
- **Route Tables**: Manages traffic routing between subnets
- **Security Groups**: Network-level firewall rules

#### 2. Compute Resources
- **EC2 Instance**: Single `t3.large` instance hosting Kubernetes
- **IAM Roles**: Secure access management for AWS services
- **Key Pairs**: SSH access management

#### 3. Storage & State Management
- **S3 Backend**: Terraform state storage with encryption
- **EBS Volumes**: Persistent storage for EC2 instances

### Terraform Module Structure
```
modules/
├── vpc/                 # Virtual Private Cloud
├── subnets/            # Public/Private subnet configuration
├── internet-gateway/   # Internet connectivity
├── route-tables/       # Network routing
├── security-groups/    # Network security rules
├── ec2/               # Compute instances
├── iam/               # Identity and Access Management
└── key-pair/          # SSH key management
```

### Key Configuration Files

The main Terraform configuration (`main.tf`) orchestrates all infrastructure modules, defining the VPC, subnets, security groups, and EC2 instances. Variable definitions are centralized in `terraform.tfvars` for easy environment-specific customization, including AWS region, network CIDR blocks, and instance specifications.

### Security Configuration

#### Network Security Groups
- **Web Security Group**: 
  - SSH (Port 22): From specified CIDR blocks
  - Airflow API (Port 30080): Public access
  - MLflow (Port 30081): Public access
  - HTTPS Egress: All outbound traffic

#### IAM Policies
- **EC2 Role**: Basic EC2 service permissions
- **CloudWatch Policy**: Metrics and logging
- **SSM Policy**: Systems Manager access
- **S3 Policy**: Artifact storage access

---

## ☸️ Kubernetes Infrastructure

### Cluster Overview
Single-node Kubernetes cluster running on EC2 with the following components:

#### Core Services
```
Namespaces:
├── airflow/          # Apache Airflow orchestration
├── mlflow/           # ML experiment tracking  
├── inference/        # Model serving API
└── longhorn-system/  # Persistent storage
```

### Application Deployments

#### 1. Apache Airflow (`k8s-infra/airflow/`)
The Airflow deployment uses a CeleryExecutor configuration with custom Docker images and GitSync integration for automatic DAG synchronization from the MLOps-Project repository. PostgreSQL serves as the metadata backend with persistent storage for logs and database credentials managed through Kubernetes secrets.

**Key Features:**
- CeleryExecutor for distributed task execution
- GitSync for automatic DAG synchronization
- PostgreSQL backend for metadata storage
- Persistent volume for logs storage

#### 2. MLflow Tracking Server (`k8s-infra/mlflow/`)
The MLflow server deployment runs a custom image configured with SQLite for experiment metadata and S3 for artifact storage. The service is exposed via NodePort 30081 and uses AWS credentials stored in Kubernetes secrets for S3 access.

**Key Features:**
- SQLite backend for experiment metadata
- S3 artifact storage for model artifacts
- Exposed on NodePort 30081

#### 3. Inference API (`k8s-infra/inference/`)
The inference service deploys a FastAPI-based application for model serving, with dynamic model loading capabilities from MLflow. The deployment includes health check endpoints and uses Nginx for load balancing, exposed through NodePort configuration.

**Key Features:**
- FastAPI-based model serving
- Dynamic model loading from MLflow
- Health check endpoints
- Nginx ingress for load balancing

### Storage Configuration

#### Persistent Volume Claims
- **Airflow Logs**: 1Gi persistent storage
- **MLflow Data**: Persistent volume for SQLite database
- **Longhorn**: Distributed storage system

#### Secrets Management
AWS credentials and MLflow configuration are managed securely through Jenkins credential store and injected during pipeline execution. The secret YAML files in the repository contain only empty templates - actual values are never committed to version control. See `SECURITY.md` for detailed secure secret management practices.

### Service Exposure

#### NodePort Services
- **Airflow UI**: `http://<ec2-ip>:30080`
- **MLflow UI**: `http://<ec2-ip>:30081`
- **Inference API**: `http://<ec2-ip>:30082`

---

## 🚀 CI/CD Pipeline

### Jenkins Pipeline (`Jenkinsfile`)
The CI/CD pipeline is configured with Docker Hub registry integration and automated stages for code checkout, linting, testing, image building, and Kubernetes deployment. The pipeline builds custom images for Airflow, MLflow, and the inference API, managing version tags and rolling updates to the cluster.

**Pipeline Stages:**
1. **Code Checkout**: Pull latest code from repository
2. **Lint & Test**: Code quality checks and unit tests
3. **Build Images**: Docker image builds for all services
4. **Deploy to Kubernetes**: Rolling updates to cluster

### Container Images
- **Custom Airflow**: `mintah/airflow-custom:latest`
- **MLflow Server**: `mintah/mlflow-server:latest`  
- **Inference API**: `mintah/inference-api:latest`

---

## 🛠️ Setup Instructions

### Prerequisites
The setup requires AWS CLI configuration, Terraform v1.0+, kubectl for Kubernetes management, and Docker for container image builds. Ensure proper AWS credentials and permissions are configured before deployment.

### 1. Terraform Deployment
Initialize Terraform with `terraform init`, review the deployment plan using `terraform plan` with the tfvars file, and apply the infrastructure changes. The deployment creates all AWS resources including VPC, subnets, security groups, and EC2 instances.

### 2. Kubernetes Setup
SSH into the provisioned EC2 instance using the generated key pair, execute the Kubernetes setup script to install Docker and kubeadm, then deploy all application manifests from the k8s-infra directory. The script handles cluster initialization and networking configuration.

### 3. Access Services
Once deployed, services are accessible via the EC2 public IP: Airflow UI on port 30080 (credentials: admin/admin), MLflow UI on port 30081, and the Inference API on port 30082 with Swagger documentation at the /docs endpoint.

---

## 📊 Monitoring & Observability

### Health Checks
- **Kubernetes Probes**: Liveness and readiness checks
- **Service Endpoints**: `/health` endpoints for all services
- **Resource Monitoring**: CPU, memory, and storage metrics

### Logging
- **Centralized Logs**: All container logs via kubectl
- **Persistent Storage**: Airflow logs stored persistently
- **Application Logs**: Structured JSON logging

---

## 🔧 Configuration Management

### Environment Variables
Terraform variables can be set via environment exports for AWS region and VPC configuration. Kubernetes secrets require base64-encoded AWS credentials and MLflow tracking URI for proper service integration and S3 access.

### Configuration Files
- `terraform.tfvars`: Terraform variable overrides
- `k8s-infra/*/values.yaml`: Kubernetes configuration
- `k8s-infra/*/secret.yaml.example`: Secret templates

---

## 🛡️ Security Best Practices

### Network Security
- **VPC Isolation**: Private network environment
- **Security Groups**: Minimal required port access
- **SSH Key Management**: Secure key pair handling

### Application Security  
- **Secrets Management**: Kubernetes secrets for credentials
- **Image Security**: Private registry for container images
- **RBAC**: Role-based access control for Kubernetes

### Data Security
- **Encryption**: EBS volume encryption
- **S3 Security**: Encrypted artifact storage
- **State Security**: Encrypted Terraform state

---

## 📝 Maintenance & Troubleshooting

### Common Issues
1. **Pod Not Starting**: Check resource limits and secrets
2. **Service Unreachable**: Verify security group rules
3. **Storage Issues**: Check PVC status and Longhorn health

### Backup Strategy
- **Terraform State**: S3 backend with versioning
- **Application Data**: Persistent volume snapshots
- **Configuration**: Git-based version control

### Scaling Considerations
- **Horizontal Scaling**: Increase replica counts
- **Vertical Scaling**: Upgrade EC2 instance types
- **Multi-AZ**: Deploy across multiple availability zones

---

## 📚 Additional Resources

### Documentation Links
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Apache Airflow on Kubernetes](https://airflow.apache.org/docs/helm-chart/)
- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)

### Support
- **Repository**: [MLOps-IAC](https://github.com/Lay-ke/MLOps-IAC)
- **Issues**: Create GitHub issues for bugs/features
- **Contact**: MLOps Team

---

*Last Updated: August 2, 2025*  
*Version: 1.0.0*