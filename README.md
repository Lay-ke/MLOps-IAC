# MLOps Infrastructure as Code (IAC)

## Overview
This repository contains the Infrastructure as Code (IAC) components for deploying and managing the MLOps pipeline infrastructure. The infrastructure is split into two main components: **Terraform** for AWS cloud resources and **Kubernetes** for containerized workload orchestration. [click to Project Info](https://github.com/Lay-ke/MLOps-Project).

---

## 🏗️ Infrastructure Architecture

### High-Level Architecture
The MLOps infrastructure is deployed on AWS Cloud within a dedicated VPC using the `10.0.0.0/16` network range. The architecture includes a public subnet (`10.0.1.0/24`) hosting the EC2 instance running Kubernetes, and a private subnet (`10.0.2.0/24`) reserved for future database deployments. The single `t3.large` EC2 instance hosts the complete Kubernetes cluster with all MLOps applications.

---

## 📦 Terraform Infrastructure

### Components Overview

#### 1. Core Network Infrastructure
The network foundation includes a Virtual Private Cloud providing an isolated network environment, public and private subnets distributed across multiple availability zones, an Internet Gateway enabling internet access for public resources, route tables managing traffic routing between subnets, and security groups implementing network-level firewall rules.

#### 2. Compute Resources
The compute layer consists of a single `t3.large` EC2 instance hosting the Kubernetes cluster, IAM roles providing secure access management for AWS services, and SSH key pairs for secure administrative access.

#### 3. Storage & State Management
Storage components include S3 backend configuration for Terraform state storage with encryption enabled, and EBS volumes providing persistent storage for EC2 instances with encryption at rest.

### Terraform Module Structure
The infrastructure is organized using modular Terraform configuration with dedicated modules for VPC networking, subnet configuration, internet gateway setup, route table management, security group definitions, EC2 instance provisioning, IAM role and policy management, and SSH key pair configuration. Module details can be found in the `terraform/modules/` directory.

### Key Configuration Files

The main Terraform configuration is located in `terraform/main.tf` and orchestrates all infrastructure modules. Variable definitions are centralized in `terraform/terraform.tfvars` for environment-specific customization including AWS region, network CIDR blocks, and instance specifications.

### Security Configuration

#### Network Security Groups
Network security is implemented through security groups defined in `terraform/modules/security-groups/`. The web security group restricts SSH access to port 22 from specified CIDR blocks, allows public access to Airflow API on port 30080 and MLflow on port 30081, and permits all outbound HTTPS traffic.

#### IAM Policies
Identity and access management policies are configured in `terraform/modules/iam/` providing EC2 service permissions, CloudWatch access for metrics and logging, Systems Manager access for configuration management, and S3 access for artifact storage.

---

## ☸️ Kubernetes Infrastructure

### Cluster Overview
The deployment runs a single-node Kubernetes cluster on EC2 with dedicated namespaces for Apache Airflow orchestration, MLflow experiment tracking, inference API for model serving, and Longhorn system for persistent storage management.

### Application Deployments

#### 1. Apache Airflow
The Airflow deployment configuration can be found in `k8s-infra/airflow/` and uses a CeleryExecutor configuration with custom Docker images. GitSync integration provides automatic DAG synchronization from the MLOps-Project repository. PostgreSQL serves as the metadata backend with persistent storage, and credentials are managed through Kubernetes secrets for enhanced security.

#### 2. MLflow Tracking Server
MLflow server deployment manifests are located in `k8s-infra/mlflow/` and run a custom image configured with SQLite for experiment metadata storage and S3 for artifact storage. The service is exposed via NodePort 30081 and uses AWS credentials stored in Kubernetes secrets for secure S3 access.

#### 3. Inference API
The inference service deployment files in `k8s-infra/inference/` deploy a FastAPI-based application for model serving with dynamic model loading capabilities from MLflow. The deployment includes health check endpoints and uses Nginx for load balancing through NodePort configuration.

### Storage Configuration

#### Persistent Volume Claims
Storage requirements include persistent storage for Airflow logs, MLflow data using persistent volumes for SQLite database, and Longhorn distributed storage system for cluster-wide storage management. Configuration details are available in respective deployment manifests.

#### Secrets Management
AWS credentials and MLflow configuration are managed securely through AWS Secrets Manager and injected during deployment execution. The secret YAML files in the repository serve as templates only - actual values are retrieved dynamically at runtime. Detailed security practices are documented in `SECURITY.md`.

### Service Exposure

Application access is provided through NodePort services with Airflow UI accessible on port 30080, MLflow UI on port 30081, and Inference API on port 30082. Service configuration details can be found in the respective service manifests.

---

## 🚀 CI/CD Pipeline

### Jenkins Pipeline
The CI/CD pipeline configuration in `Jenkinsfile` includes Docker Hub registry integration and automated stages for code checkout, linting and testing, image building for all services, and Kubernetes deployment with rolling updates. The pipeline builds custom images for Airflow, MLflow, and the inference API while managing version tags and cluster updates.

### Container Images
The deployment uses custom Docker images including `mintah/airflow-custom:latest` for Airflow with custom dependencies, `mintah/mlflow-server:latest` for MLflow tracking server, and `mintah/inference-api:latest` for the model serving API.

---

## 🛠️ Setup Instructions

### Prerequisites
Setup requirements include AWS CLI configuration with appropriate credentials, Terraform v1.0+ installation, kubectl for Kubernetes cluster management, and Docker for container image operations. Ensure proper AWS permissions are configured before beginning deployment.

### 1. Terraform Deployment
Initialize Terraform using the configuration in `terraform/` directory, review the deployment plan with your terraform.tfvars file, and apply the infrastructure changes. The deployment process creates all required AWS resources including networking, security, and compute components.

### 2. Kubernetes Setup
Access the provisioned EC2 instance using the generated SSH key pair, execute the Kubernetes setup script located at `scripts/new_script.sh` to install and configure the cluster, then deploy all application manifests from the `k8s-infra/` directory. The script handles complete cluster initialization and application deployment.

### 3. Access Services
Once deployment completes, access services through the EC2 public IP address: Airflow UI on port 30080 with admin/admin credentials, MLflow UI on port 30081 without authentication, and Inference API on port 30082 with Swagger documentation available at the /docs endpoint.

---

## 📊 Monitoring & Observability

### Health Checks
Monitoring capabilities include Kubernetes liveness and readiness probes for all services, health check endpoints available at `/health` for all applications, and comprehensive resource monitoring for CPU, memory, and storage metrics.

### System Performance Monitoring
System performance monitoring is implemented using Prometheus for metrics collection and Grafana for visualization dashboards. This comprehensive monitoring stack is enabled through StatsD integration, which collects and forwards metrics from Airflow and other applications to Prometheus. The monitoring setup provides real-time insights into system performance, application metrics, and infrastructure health, allowing for proactive monitoring and alerting of the MLOps platform.

### Logging
Centralized logging is implemented through kubectl for all container logs, persistent storage for Airflow logs to ensure log retention, and structured JSON logging for all applications to facilitate log analysis and monitoring.

---

## 🔧 Configuration Management

### Environment Variables
Configuration management uses Terraform variables set through environment exports for AWS region and VPC configuration. Kubernetes secrets store base64-encoded AWS credentials and MLflow tracking URI for secure service integration and S3 access.

### Configuration Files
Key configuration files include `terraform/terraform.tfvars` for Terraform variable overrides, various `values.yaml` files in `k8s-infra/` directories for Kubernetes configuration, and `secret.yaml.example` templates in each namespace directory for secret configuration guidance.

---

## 🛡️ Security Best Practices

### Network Security
Security implementation includes VPC isolation providing a private network environment, security groups configured with minimal required port access, and SSH key management for secure administrative access to resources.

### Application Security
Application-level security features Kubernetes secrets for credential management, private registry usage for container images, and role-based access control (RBAC) for Kubernetes resource access.

### Data Security
Data protection includes EBS volume encryption for data at rest, encrypted S3 artifact storage for ML models and data, and encrypted Terraform state management for infrastructure configuration security.

---

## 🚀 Deployment Walkthrough

### Prerequisites Checklist

Before deployment, ensure you have an AWS account with appropriate permissions, AWS CLI configured with credentials, Terraform v1.0+ installed locally, an SSH key pair created for EC2 access, and Git installed for repository management.

### Step 1: Clone and Prepare Repository

Clone the MLOps-IAC repository from GitHub and navigate to the project directory to review the infrastructure configuration files located in the terraform directory.

### Step 2: Create AWS Secrets in Secrets Manager

**Important**: Before deployment, create required secrets in AWS Secrets Manager for the userdata script to retrieve securely. Create a secret named "my_secret" containing your AWS credentials including `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION`.

The secret can be created using AWS CLI with the `secretsmanager create-secret` command or through the AWS Console by navigating to Secrets Manager, selecting "Store a new secret", choosing "Other type of secret", and adding the required key-value pairs. Verify creation using the `secretsmanager list-secrets` command.

### Step 3: Customize Terraform Variables

Copy the example terraform variables file from `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and customize key variables including AWS region, environment name, VPC CIDR blocks, subnet configurations, EC2 instance type, and existing SSH key pair name.

### Step 4: Deploy AWS Infrastructure with Userdata

Navigate to the terraform directory and initialize Terraform, review the deployment plan, and apply the infrastructure configuration. This process creates AWS resources within 2 minutes and automatically executes the userdata script for 15-20 minutes to set up the complete MLOps environment.

### Step 5: Monitor Deployment Progress

Retrieve the EC2 instance public IP and instance ID using Terraform outputs. Monitor deployment progress by SSH-ing into the instance and observing the userdata script execution through log files located at `/var/log/k8s-data.log`. Additional monitoring is available through cloud-init status commands and AWS Console services.

### Step 6: Verify Deployment Completion

Deployment completion is indicated by the "Kubernetes cluster setup complete" message in the logs. Verify successful deployment by checking Kubernetes cluster status, confirming all pods are running across namespaces, and validating service accessibility.

### Step 7: Access Applications

Access the MLOps platform through the EC2 public IP address: Airflow UI on port 30080 with admin credentials, MLflow UI on port 30081 without authentication requirements, and Inference API on port 30082 with API documentation available at the /docs endpoint.

### Step 8: Validate End-to-End Setup

Validate the complete setup by testing service endpoints using curl commands to verify Airflow, MLflow, and Inference API health endpoints respond correctly.

### Troubleshooting Common Issues

Common troubleshooting scenarios include userdata script failures (check cloud-init status and logs), services not starting (verify Kubernetes pod status and resources), and AWS credential issues (confirm secrets manager configuration and Kubernetes secret creation).

### Deployment Timeline

Expect a total deployment duration of 20-25 minutes: AWS resources creation (0-2 minutes), EC2 instance boot and userdata start (2-5 minutes), system updates and Docker installation (5-8 minutes), Kubernetes cluster initialization (8-13 minutes), application deployments (13-20 minutes), and full service availability (20+ minutes).

### Clean Up Resources

Resource cleanup is accomplished by running `terraform destroy` from the terraform directory, which removes all created AWS resources and associated costs.

### Production Considerations

Production deployments should implement IAM roles instead of hardcoded credentials, AWS Secrets Manager for secure secret storage, CloudWatch alarms and dashboards for monitoring, auto-scaling groups for high availability, centralized logging with CloudWatch, and automated backup strategies for data protection.

---

## 🔐 Security & Credentials Setup

### AWS Credentials

AWS credentials are required for Terraform provisioning and Kubernetes deployments. Handle credentials securely using AWS CLI configuration for initial setup, with access keys having minimal required permissions and regular rotation schedules.

For enhanced security, especially in production environments, implement IAM roles with EC2 instance profiles to avoid hardcoded credentials and enable automatic credential rotation. Create IAM roles with necessary permissions and attach them to EC2 instances as detailed in the IAM module configuration.

### Kubernetes Secrets

Kubernetes secrets manage sensitive information including AWS credentials, database passwords, and API keys. Secrets are base64-encoded and stored securely in the Kubernetes API server, accessible only to authorized pods and users within the same namespace.

Create secrets using kubectl commands or YAML manifest files, ensuring secrets are created in the appropriate namespace for application access. Reference secrets in deployment specifications as environment variables or mounted files as shown in the deployment manifests.

### Best Practices for Managing Secrets

Security best practices include using IAM roles for EC2 instances to avoid access keys, limiting secret access to authorized users only, implementing regular secret and access key rotation, monitoring and auditing secret access, and using encryption for sensitive data both at rest and in transit.

---

## 🛠️ Maintenance & Troubleshooting

### Common Issues

Troubleshooting guidance covers pods not starting (check resource limits and secret configuration), services being unreachable (verify security group rules and network configuration), and storage issues (check PVC status and Longhorn storage health).

### Backup Strategy

Implement comprehensive backup strategies including Terraform state management with S3 backend and versioning, application data protection through persistent volume snapshots, and configuration management using Git-based version control for all infrastructure code.

### Scaling Considerations

Scale the infrastructure through horizontal scaling by increasing replica counts for applications, vertical scaling by upgrading EC2 instance types for increased performance, and multi-AZ deployment for high availability and fault tolerance.

---

## 📚 Additional Resources

### Documentation Links
Additional documentation includes Terraform AWS Provider documentation, official Kubernetes documentation, Apache Airflow on Kubernetes deployment guides, and MLflow documentation for ML experiment tracking and model management.

### Support
Project support is available through the MLOps-IAC GitHub repository for code access, GitHub issues for bug reports and feature requests, and direct contact with the MLOps team for additional assistance.

---

*Last Updated: August 13, 2025*  
*Version: 1.0.0*