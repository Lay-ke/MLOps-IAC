# MLOps Infrastructure as Code (IAC)

## Overview
This repository contains the Infrastructure as Code (IAC) components for deploying and managing the MLOps pipeline infrastructure. The infrastructure is split into two main components: **Terraform** for AWS cloud resources and **Kubernetes** for containerized workload orchestration. [click to Project Info](https://github.com/Lay-ke/MLOps-Project).

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

---

## 🚀 Deployment Walkthrough

### Prerequisites Checklist

Before starting the deployment, ensure you have:

- **AWS Account** with appropriate permissions
- **AWS CLI** configured with your credentials
- **Terraform** v1.0+ installed
- **SSH Key Pair** for EC2 access
- **Git** for cloning repositories

### Step 1: Clone and Prepare Repository

```bash
# Clone the IAC repository
git clone https://github.com/Lay-ke/MLOps-IAC.git
cd MLOps-IAC

# Review the infrastructure configuration
ls -la terraform/
```

### Step 2: Create AWS Secrets in Secrets Manager

⚠️ **Important**: Before deployment, you must create the required secrets in AWS Secrets Manager for the userdata script to retrieve.

**Create the secret with AWS CLI:**
```bash
# Create the secret with all required AWS credentials
aws secretsmanager create-secret \
    --name "my_secret" \
    --description "MLOps infrastructure AWS credentials" \
    --secret-string '{
        "AWS_ACCESS_KEY_ID": "your-actual-access-key-id",
        "AWS_SECRET_ACCESS_KEY": "your-actual-secret-access-key", 
        "AWS_DEFAULT_REGION": "us-east-1"
    }'
```

**Alternative: Create via AWS Console**
1. Go to **AWS Secrets Manager** in the AWS Console
2. Click **Store a new secret**
3. Select **Other type of secret**
4. Add the following key-value pairs:
   - `AWS_ACCESS_KEY_ID`: your-actual-access-key-id
   - `AWS_SECRET_ACCESS_KEY`: your-actual-secret-access-key
   - `AWS_DEFAULT_REGION`: your-region
5. Name the secret: `my_secret`
6. Complete the creation process

**Verify the secret was created:**
```bash
# List secrets to confirm creation
aws secretsmanager list-secrets --query 'SecretList[?Name==`my_secret`]'

# Test retrieval (optional)
aws secretsmanager get-secret-value --secret-id my_secret --query SecretString --output text
```

### Step 3: Customize Terraform Variables

```bash
# Copy and edit the terraform variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit variables to match your requirements
nano terraform/terraform.tfvars
```

**Key variables to configure:**
```hcl
aws_region          = "us-east-1"
environment         = "dev"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
instance_type      = "t3.large"
key_name           = "your-existing-key-pair-name"
```

### Step 4: Deploy AWS Infrastructure with Userdata

```bash
# Navigate to terraform directory
cd terraform/

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Apply the infrastructure - this automatically runs the setup script
terraform apply
```

**What happens during deployment:**
1. **AWS Resources Created** (~2 minutes)
   - VPC, subnets, security groups
   - EC2 instance launched with userdata script
   
2. **Userdata Script Execution** (~15-20 minutes)
   - System updates and Docker installation
   - Kubernetes cluster initialization
   - Application deployment (Airflow, MLflow, Inference API)

### Step 5: Monitor Deployment Progress

**Get instance information:**
```bash
# Get the EC2 instance public IP
EC2_IP=$(terraform output -raw ec2_public_ip)
echo "EC2 Public IP: $EC2_IP"

# Get instance ID for CloudWatch logs
INSTANCE_ID=$(terraform output -raw ec2_instance_id)
echo "Instance ID: $INSTANCE_ID"
```

**Monitor via SSH:**
```bash
# SSH into the instance (wait 2-3 minutes after launch)
ssh -i ~/.ssh/your-key.pem ubuntu@$EC2_IP

# Monitor the userdata script progress
sudo tail -f /var/log/k8s-data.log

# Check cloud-init status
sudo cloud-init status

# View cloud-init logs if needed
sudo journalctl -u cloud-final -f
```

**Monitor via AWS Console:**
- **EC2 Console**: Check instance status and system logs
- **CloudWatch**: View instance metrics and custom logs
- **VPC Console**: Verify network configuration

### Step 6: Verify Deployment Completion

**The userdata script completes when you see:**
```
[+] Kubernetes cluster setup complete.
```

**Verify services are running:**
```bash
# SSH into the instance
ssh -i ~/.ssh/your-key.pem ubuntu@$EC2_IP

# Check Kubernetes cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Verify all pods are running
kubectl get pods -n airflow
kubectl get pods -n mlflow
kubectl get pods -n inference
```

### Step 7: Access Applications

**Your MLOps platform will be automatically accessible at:**

- **Airflow UI**: `http://$EC2_IP:30080`
  - Username: `admin`
  - Password: `admin`

- **MLflow UI**: `http://$EC2_IP:30081`
  - No authentication required

- **Inference API**: `http://$EC2_IP:30082`
  - API Documentation: `http://$EC2_IP:30082/docs`

### Step 8: Validate End-to-End Setup

```bash
# Test service endpoints (run from your local machine)
curl -f http://$EC2_IP:30080/health || echo "Airflow not ready"
curl -f http://$EC2_IP:30081/health || echo "MLflow not ready"
curl -f http://$EC2_IP:30082/health || echo "Inference API not ready"
```

### Troubleshooting Userdata Issues

#### Issue 1: Userdata Script Fails
```bash
# SSH into instance and check userdata logs
ssh -i ~/.ssh/your-key.pem ubuntu@$EC2_IP

# Check cloud-init status
sudo cloud-init status

# View detailed logs
sudo cat /var/log/cloud-init-output.log
sudo journalctl -u cloud-final

# Check custom script logs
sudo tail -100 /var/log/k8s-data.log
```

#### Issue 2: Services Not Starting
```bash
# Check if userdata completed
sudo cloud-init status

# If completed, check Kubernetes
kubectl get pods --all-namespaces
kubectl describe pod <failing-pod> -n <namespace>

# Check node resources
kubectl describe node
```

#### Issue 3: AWS Credential Issues
```bash
# Verify credentials were set correctly
kubectl get secrets -n airflow aws-credentials -o yaml

# Check if secrets contain data
kubectl get secret aws-credentials -n airflow -o jsonpath='{.data}'
```

### Deployment Timeline

**Expected deployment duration: 20-25 minutes**

- **0-2 min**: AWS resources creation
- **2-5 min**: EC2 instance boot and userdata start
- **5-8 min**: System updates and Docker installation
- **8-13 min**: Kubernetes cluster initialization
- **13-20 min**: Application deployments
- **20+ min**: Services ready for access

### Clean Up Resources

```bash
# Destroy all AWS resources
cd terraform/
terraform destroy

# Confirm destruction
# Type 'yes' when prompted
```

**Cost Estimate:**
- **t3.large EC2**: ~$0.08/hour (~$2/day)
- **EBS Storage (8GB)**: ~$0.80/month
- **Data Transfer**: Minimal for testing

### Production Considerations

For production deployments:

1. **Use IAM Roles**: Replace hardcoded credentials with EC2 instance profiles
2. **Implement Parameter Store**: Store secrets in AWS Systems Manager
3. **Add Monitoring**: Configure CloudWatch alarms and dashboards
4. **Use Auto Scaling**: Implement auto-scaling groups for HA
5. **Enable Logging**: Set up centralized logging with CloudWatch
6. **Backup Strategy**: Configure automated snapshots and backups

---

## 🔐 Security & Credentials Setup

### AWS Credentials

AWS credentials are required for Terraform and Kubernetes setups to provision resources and manage deployments. It is crucial to handle these credentials securely to prevent unauthorized access.

#### 1. AWS Access Keys

For initial setup, AWS access keys are used. These keys should have minimal required permissions and be rotated regularly.

- **Access Key ID**: Your access key ID
- **Secret Access Key**: Your secret access key

**Configure AWS CLI:**
```bash
aws configure
```

#### 2. IAM Roles (Recommended for Production)

For enhanced security, especially in production, use IAM roles with EC2 instance profiles. This approach avoids hardcoding credentials and allows for automatic credential rotation.

- **Create an IAM Role** with the necessary permissions
- **Attach the Role** to your EC2 instance

**Example IAM Policy for EC2 Role:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "logs:*",
        "cloudwatch:*",
        "ssm:*",
        "ecs:*",
        "eks:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Kubernetes Secrets

Kubernetes secrets are used to manage sensitive information such as AWS credentials, database passwords, and API keys. Secrets are base64-encoded and stored in the Kubernetes API server, accessible only to authorized pods and users.

#### 1. Create Secrets

Secrets can be created using YAML files or kubectl command-line tool. Ensure secrets are created in the same namespace as the application.

**Example: Create AWS Credentials Secret**
```bash
kubectl create secret generic aws-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=your-access-key-id \
  --from-literal=AWS_SECRET_ACCESS_KEY=your-secret-access-key \
  -n airflow
```

#### 2. Reference Secrets in Deployments

Secrets can be referenced in pod specifications as environment variables or mounted as files.

**Example: Reference AWS Credentials in Airflow Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: airflow
  namespace: airflow
spec:
  template:
    spec:
      containers:
      - name: airflow
        image: mintah/airflow-custom:latest
        env:
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: AWS_ACCESS_KEY_ID
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: AWS_SECRET_ACCESS_KEY
```

### Best Practices for Managing Secrets

- **Use IAM Roles** for EC2 instances to avoid using access keys
- **Limit Secret Access** to only those who need it
- **Regularly Rotate Secrets** and access keys
- **Monitor and Audit** access to secrets
- **Use Encryption** for sensitive data at rest and in transit

---

## 🛠️ Maintenance & Troubleshooting

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