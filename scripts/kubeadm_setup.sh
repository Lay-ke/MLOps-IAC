#!/bin/bash

# Log output
exec > >(tee /var/log/k8s-data.log) 2>&1

# Exit on any error
set -e

# Set home directory
APP_HOME="/home/ubuntu"

echo "App Home Directory: $APP_HOME"

# Ensure the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "Please run this script with sudo or as root"
   exit 1
fi

# Function to update system packages
update_system() {
    echo "[+] Updating system packages"
    apt update && apt upgrade -y
}

get_secret_from_secrets_manager() {
    echo "[+] Retrieving secrets from AWS Secrets Manager"
    AWS_ACCESS_KEY_ID=$(aws secretsmanager get-secret-value --secret-id my_secret --query SecretString --output text | jq -r .AWS_ACCESS_KEY_ID)
    AWS_SECRET_ACCESS_KEY=$(aws secretsmanager get-secret-value --secret-id my_secret --query SecretString --output text | jq -r .AWS_SECRET_ACCESS_KEY)
    AWS_DEFAULT_REGION=$(aws secretsmanager get-secret-value --secret-id my_secret --query SecretString --output text | jq -r .AWS_DEFAULT_REGION)
}

# Function to disable swap (required by Kubernetes)
disable_swap() {
    echo "[+] Disabling swap"
    sudo swapoff -a
    sudo sed -i '/ swap / s/^/#/' /etc/fstab
}

# Function to load required kernel modules
load_kernel_modules() {
    echo "[+] Loading necessary kernel modules"
    sudo modprobe overlay
    sudo modprobe br_netfilter
    sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
    sudo sysctl --system
}

# Function to install NFS client
install_nfs_client() {
    echo "[+] Installing NFS client"
    sudo apt install -y nfs-common
}

# Function to install Docker
install_docker() {
    echo "[+] Installing Docker"
    sudo apt-get install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
}

# Function to configure containerd to use systemd cgroup
configure_containerd() {
    echo "[+] Configuring containerd"
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    sudo systemctl restart containerd
    sudo systemctl enable containerd
}

# Function to install Kubernetes (kubeadm, kubelet, kubectl)
install_kubernetes() {
    echo "[+] Installing Kubernetes"
    sudo apt install -y apt-transport-https ca-certificates curl gpg
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt update

    sudo apt install -y kubeadm kubelet kubectl
    sudo apt-mark hold kubeadm kubelet kubectl
}

# Function to initialize Kubernetes
initialize_kubernetes() {
    echo "[+] Initializing Kubernetes"
    sudo kubeadm init --pod-network-cidr=10.0.0.0/16

    echo "[+] Waiting for /etc/kubernetes/admin.conf to be generated..."
    while [ ! -f /etc/kubernetes/admin.conf ]; do
        sleep 5
    done

    echo "[+] Setting up kubeconfig"

    echo "[+] Setting ownership of kubeconfig to ubuntu user"
    mkdir -p $APP_HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $APP_HOME/.kube/config
    sudo chown ubuntu:ubuntu $APP_HOME/.kube/config

    export KUBECONFIG=$APP_HOME/.kube/config
    echo "export KUBECONFIG=$APP_HOME/.kube/config" >> $APP_HOME/.bashrc
}

taint_nodes() {
    echo "[+] Tainting control-plane nodes"
    kubectl taint nodes --all node-role.kubernetes.io/control-plane-

    sleep 20

    echo "[+] Waiting for Kubernetes nodes to be ready"
    kubectl wait --for=condition=Ready nodes --all --timeout=180s
}

# Function to install Helm
install_helm() {
    echo "[+] Installing Helm"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    helm version
}

# Function to install and configure Cilium CNI
install_cilium() {
    echo "[+] Installing Cilium CNI"
    curl -L --remote-name https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
    sudo tar xzvf cilium-linux-amd64.tar.gz -C /usr/local/bin
    rm cilium-linux-amd64.tar.gz

    # Ensure we can access the cluster
    export KUBECONFIG=$APP_HOME/.kube/config

    echo "[+] Installing Cilium"
    cilium install
}

install_longhorn() {
    echo "[+] Installing Longhorn"
    kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
    kubectl label node $(hostname) node.longhorn.io/create-default-disk=true
}

# Function to check for Kubernetes node readiness
wait_for_kubernetes_nodes() {
    echo "[+] Waiting for Kubernetes nodes to be ready"
    kubectl wait --for=condition=Ready nodes --all --timeout=180s
}

# Function to create Kubernetes secrets
create_kubernetes_secrets() {
    echo "[+] Creating Kubernetes secrets"
    
    # Create secrets for each namespace
    kubectl create namespace airflow --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace mlflow --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace inference --dry-run=client -o yaml | kubectl apply -f -
    
    # AWS credentials secret for airflow namespace
    kubectl create secret generic aws-credentials \
        --from-literal=AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
        --from-literal=AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
        --from-literal=AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
        --namespace=airflow \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # AWS credentials secret for mlflow namespace
    kubectl create secret generic aws-credentials \
        --from-literal=AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
        --from-literal=AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
        --from-literal=AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
        --namespace=mlflow \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # AWS credentials secret for inference namespace
    kubectl create secret generic aws-credentials \
        --from-literal=AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
        --from-literal=AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
        --from-literal=AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
        --namespace=inference \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Airflow admin credentials
    kubectl create secret generic airflow-admin \
        --from-literal=username="${AIRFLOW_ADMIN_USER:-admin}" \
        --from-literal=password="${AIRFLOW_ADMIN_PASSWORD:-admin}" \
        --namespace=airflow \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Airflow database credentials
    kubectl create secret generic airflow-db \
        --from-literal=username="${AIRFLOW_DB_USER:-airflow}" \
        --from-literal=password="${AIRFLOW_DB_PASSWORD:-airflow}" \
        --from-literal=database="${AIRFLOW_DB_NAME:-airflow}" \
        --namespace=airflow \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # MLflow configuration secret
    kubectl create secret generic mlflow-config \
        --from-literal=MLFLOW_TRACKING_URI="http://mlflow-server.mlflow.svc.cluster.local:5000" \
        --from-literal=INFERENCE_API_URL="http://inference-service.inference.svc.cluster.local:8000" \
        --namespace=airflow \
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic mlflow-config \
        --from-literal=MLFLOW_TRACKING_URI="http://mlflow-server.mlflow.svc.cluster.local:5000" \
        --namespace=mlflow \
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic mlflow-config \
        --from-literal=MLFLOW_TRACKING_URI="http://mlflow-server.mlflow.svc.cluster.local:5000" \
        --namespace=inference \
        --dry-run=client -o yaml | kubectl apply -f -
    
    echo "[+] Kubernetes secrets created successfully"
}

# Function to install and configure Airflow with Helm
install_airflow() {
    echo "[+] Installing Apache Airflow"
    helm repo add apache-airflow https://airflow.apache.org
    helm repo update

    cat << EOF > $APP_HOME/fixed-values.yaml
executor: "CeleryExecutor"

images:
  airflow:
    repository: mintah/airflow-custom
    tag: latest

extraEnv: |-
  - name: CONFIG_PATH
    value: /opt/airflow/dags/repo/configs/config.yaml
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
  - name: AWS_DEFAULT_REGION
    valueFrom:
      secretKeyRef:
        name: aws-credentials
        key: AWS_DEFAULT_REGION
  - name: MLFLOW_TRACKING_URI
    valueFrom:
      secretKeyRef:
        name: mlflow-config
        key: MLFLOW_TRACKING_URI
  - name: INFERENCE_API_URL
    valueFrom:
      secretKeyRef:
        name: mlflow-config
        key: INFERENCE_API_URL
  - name: AIRFLOW__METRICS__STATSD_ON
    value: "True"
  - name: AIRFLOW__METRICS__STATSD_HOST
    value: statsd-exporter.monitoring.svc.cluster.local
  - name: AIRFLOW__METRICS__STATSD_PORT
    value: "9125"
  - name: AIRFLOW__METRICS__STATSD_PREFIX
    value: airflow


dags:
  persistence:
    enabled: false
    size: 1Gi
    storageClassName: longhorn
  gitSync:
    enabled: true
    repo: https://github.com/Lay-ke/MLOps-Project.git
    branch: main
    rev: HEAD
    depth: 1
    subPath: pipelines

logs:
  persistence:
    enabled: true
    size: 1Gi
    storageClassName: longhorn

postgresql:
  enabled: true
  auth:
    username: airflow
    password: airflow
    database: airflow
  primary:
    persistence:
      enabled: true
      size: 8Gi
      storageClass: longhorn

redis:
  enabled: true
  persistence:
    enabled: true
    size: 1Gi

data:
  metadataConnection:
    user: airflow
    pass: airflow
    protocol: postgresql
    host: airflow-postgresql
    port: 5432
    db: airflow
    sslmode: disable

flower:
  enabled: false

web:
  defaultUser:
    enabled: true
    username: admin
    password: admin

service:
  type: NodePort
  nodePort: 30080
EOF

    helm upgrade --install airflow apache-airflow/airflow \
        --namespace airflow \
        --create-namespace \
        --values $APP_HOME/fixed-values.yaml
}

# Function to patch CoreDNS for GitHub sync
patch_coredns() {
    echo "[+] Patching CoreDNS for GitHub sync"
    kubectl -n kube-system patch configmap coredns \
    --type merge \
    -p '{
      "data": {
        "Corefile": ".:53 {\n    errors\n    health\n    ready\n    kubernetes cluster.local in-addr.arpa ip6.arpa {\n       pods insecure\n       fallthrough in-addr.arpa ip6.arpa\n       ttl 30\n    }\n    prometheus :9153\n    forward . 1.1.1.1 8.8.8.8\n    cache 30\n    loop\n    reload\n    loadbalance\n}"
      }
    }'

    kubectl rollout restart deployment coredns -n kube-system
    echo "[+] CoreDNS patched successfully"
}

# Function to set Airflow worker processes
set_airflow_worker_processes() {
    echo "[+] Setting Airflow worker processes"
    kubectl patch deployment airflow-api-server -n airflow \
    --type='json' \
    -p='[
      {"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["airflow", "api-server", "--workers", "1"]}
    ]'
}

# Function to expose Airflow API server
expose_airflow_api_server() {
    echo "[+] Exposing Airflow API server"
    kubectl patch svc airflow-api-server -n airflow \
    -p '{"spec": {"type": "NodePort", "ports": [{"port": 8080, "targetPort": 8080, "protocol": "TCP", "nodePort": 30080}]}}'
}

# Function to setup mlflow
setup_mlflow() {
    echo "[+] Setting up MLFlow"
    sudo mkdir -p $APP_HOME/mlflow

    cat << EOF > $APP_HOME/mlflow/mlflow-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mlflow-pvc
  namespace: mlflow
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: longhorn
EOF

    sudo cat <<EOF > $APP_HOME/mlflow/mlflow-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mlflow-server
  namespace: mlflow
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mlflow
  template:
    metadata:
      labels:
        app: mlflow
    spec:
      containers:
        - name: mlflow
          image: mintah/mlflow-server:latest
          args:
            - mlflow
            - server
            - --host=0.0.0.0
            - --port=5000
            - --backend-store-uri=sqlite:///mlflow/mlflow.db
            - --default-artifact-root=s3://ml-artifact-bucket-1
          ports:
            - containerPort: 5000
          env:
            - name: MLFLOW_TRACKING_URI
              valueFrom:
                secretKeyRef:
                  name: mlflow-config
                  key: MLFLOW_TRACKING_URI
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
            - name: AWS_DEFAULT_REGION
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: AWS_DEFAULT_REGION
          volumeMounts:
            - name: mlflow-pv
              mountPath: /mlflow
      volumes:
        - name: mlflow-pv
          persistentVolumeClaim:
            claimName: mlflow-pvc
EOF

    cat <<EOF > $APP_HOME/mlflow/mlflow-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: mlflow-server
  namespace: mlflow
spec:
  selector:
    app: mlflow
  type: NodePort
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
      nodePort: 30081
EOF

    kubectl apply -f $APP_HOME/mlflow/
}

# Function to install and configure Inference server
install_inference_server() {
    echo "[+] Installing Inference server"
    sudo mkdir -p $APP_HOME/inference

    cat << EOF > $APP_HOME/inference/inference-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inference-app
  namespace: inference
spec:
  replicas: 1
  selector:
    matchLabels:
      app: inference-app
  template:
    metadata:
      labels:
        app: inference-app
    spec:
      containers:
      - name: inference-container
        image: mintah/inference-api-image:latest
        ports:
        - containerPort: 8000
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
        - name: AWS_DEFAULT_REGION
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: AWS_DEFAULT_REGION
        - name: MLFLOW_TRACKING_URI
          valueFrom:
            secretKeyRef:
              name: mlflow-config
              key: MLFLOW_TRACKING_URI
---
apiVersion: v1
kind: Service
metadata:     
  name: inference-service
  namespace: inference
spec:
  selector:
    app: inference-app
  ports:
  - protocol: TCP
    port: 8000
    targetPort: 8000
    nodePort: 30082
  type: NodePort
EOF

cat <<EOF > $APP_HOME/inference/nginx.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: inference-ingress
  namespace: inference
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  rules:
  - host: inference.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: inference-service
            port:
              number: 8000
EOF

    kubectl apply -f $APP_HOME/inference/

    echo "[+] Inference server installed and configured"
}

# Function to setup monitoring and logging
setup_monitoring_logging() {
    echo "[+] Setting up monitoring and logging"
    
    mkdir -p $APP_HOME/monitoring

    cat <<EOF > $APP_HOME/monitoring/prometheus-values.yaml
alertmanager:
  enabled: false

pushgateway:
  enabled: false

kubeStateMetrics:
  enabled: false

nodeExporter:
  enabled: false

server:
  service:
    type: NodePort
    nodePort: 30090

  persistentVolume:
    enabled: true
    size: 2Gi
    storageClass: longhorn

  extraScrapeConfigs:
    - job_name: 'statsd-exporter'
      static_configs:
        - targets: ['statsd-exporter.monitoring.svc.cluster.local:9102']
EOF

    cat <<EOF > $APP_HOME/monitoring/grafana-values.yaml
adminUser: admin
adminPassword: admin

service:
  type: NodePort
  nodePort: 30091
  port: 80

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-server.monitoring.svc.cluster.local
        access: proxy
        isDefault: true

env:
  GF_SECURITY_DISABLE_INITIAL_ADMIN_PASSWORD_CHANGE: "true"
EOF

  echo "[+] Adding Prometheus and Grafana Helm repositories"
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  helm repo add grafana https://grafana.github.io/helm-charts
  helm repo update

  kubectl create namespace monitoring || true
  
  echo "[+] Installing Prometheus and Grafana using Helm"

  helm install statsd-exporter prometheus-community/prometheus-statsd-exporter \
  --namespace monitoring

  helm upgrade --install prometheus prometheus-community/prometheus \
  -f prometheus-values.yaml \
  --namespace monitoring

  helm upgrade --install grafana grafana/grafana \
  -f grafana-values.yaml \
  --namespace monitoring

  echo "[+] Monitoring and logging setup complete"
}

setup_argo_cd() {
    echo "[+] Setting up Argo CD"
    mkdir -p $APP_HOME/argo

    echo "[+] Creating Argo CD values file"
    cat <<EOF > $APP_HOME/argo/argo-values.yaml
server:
  service:
    type: NodePort
    servicePortHttp: 80
    servicePortHttps: 443
  extraArgs:
    - --insecure          # optional, for dev only
configs:
  secret:
    argocdServerAdminPassword: "$2a$10$EXAMPLE_HASH"  # bcrypt hashed password
  cm:
    kustomize.buildOptions: "--enable-alpha-plugins"
controller:
  replicas: 1
repoServer:
  replicas: 1
applicationSet:
  enabled: true
dex:
  enabled: false 

EOF

    cat <<EOF > $APP_HOME/argo/airflow-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: airflow
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/Lay-ke/MLOps-IAC.git'
    targetRevision: main
    path: k8s-infra/airflow
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: airflow
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

    cat <<EOF > $APP_HOME/argo/inference-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: inference
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/Lay-ke/MLOps-IAC.git'
    targetRevision: main
    path: k8s-infra/inference
  destination:
    server: https://kubernetes.default.svc
    namespace: inference
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

    kubectl create namespace argocd || true

    echo "[+] Adding Argo CD Helm repository and installing Argo CD"
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update

    echo "[+] Installing Argo CD"
    helm install argocd argo/argo-cd \
      --namespace argocd \
      -f $APP_HOME/argo/argo-values.yaml

    echo "[+] Waiting for Argo CD to be ready"
    kubectl rollout status deployment/argocd-server -n argocd

    # echo "[+] Applying Airflow application manifest"
    # kubectl apply -f $APP_HOME/argo/airflow-app.yaml

    echo "[+] Applying Inference application manifest"
    kubectl apply -f $APP_HOME/argo/inference-app.yaml

    echo "[+] Argo CD setup complete"
}

# Main execution starts here

# Update system
update_system

# Disable swap for Kubernetes
disable_swap

# Load kernel modules for Kubernetes
load_kernel_modules

# Install Docker
install_docker

# Install NFS client
install_nfs_client

# Configure containerd with systemd
configure_containerd

# Install Kubernetes
install_kubernetes

# Install Helm
install_helm

# Initialize Kubernetes Cluster
initialize_kubernetes

# Install Cilium CNI
install_cilium

# Taint control-plane nodes
taint_nodes

# Wait for Kubernetes nodes to be ready
wait_for_kubernetes_nodes

# Install Longhorn
install_longhorn

# Create Kubernetes secrets BEFORE installing applications
create_kubernetes_secrets

# Patch CoreDNS for GitHub sync
patch_coredns

# Install and configure Airflow
install_airflow

# Set Airflow worker processes
set_airflow_worker_processes

# Expose Airflow API server
expose_airflow_api_server

# Set up MLFlow
setup_mlflow

# Install and configure Inference server
install_inference_server

# Setup monitoring and logging
setup_monitoring_logging

# Setup Argo CD
setup_argo_cd

echo "[+] Kubernetes cluster setup complete."
