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
}

taint_nodes() {
    echo "[+] Checking if kube config file exists"
    echo ${APP_HOME}/.kube/config
    cat ${APP_HOME}/.kube/config || {
        echo "[-] kube config file not found, waiting for it to be created..."
        sleep 5
    }

    echo "[+] Waiting for Kubernetes API server to be ready..."
    until kubectl version --short &>/dev/null; do
      echo "  - Waiting for API server..."
      sleep 5
    done

    echo "[+] Tainting control-plane nodes"
    kubectl taint nodes --all node-role.kubernetes.io/control-plane-
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
    cilium install
}

# Function to check for Kubernetes node readiness
wait_for_kubernetes_nodes() {
    echo "[+] Waiting for Kubernetes nodes to be ready"
    kubectl wait --for=condition=Ready nodes --all --timeout=180s
}

# Function to install and configure Airflow with Helm
install_airflow() {
    echo "[+] Installing Apache Airflow"
    helm repo add apache-airflow https://airflow.apache.org
    helm repo update

    kubectl create namespace airflow

    cat << EOF > $APP_HOME/fixed-values.yaml
executor: "CeleryExecutor"

images:
  airflow:
    repository: mintah/airflow-custom
    tag: latest

env:
  - name: CONFIG_PATH
    value: /opt/airflow/dags/repo/configs/config.yaml
  - name: AWS_ACCESS_KEY_ID
    value: ""
  - name: AWS_SECRET_ACCESS_KEY
    value: ""
  - name: AWS_DEFAULT_REGION
    value: "us-east-1"

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
EOF

    helm upgrade --install airflow apache-airflow/airflow \
        --namespace airflow \
        --create-namespace \
        --values $APP_HOME/fixed-values.yaml
}

# Function to install Longhorn
install_longhorn() {
    echo "[+] Installing Longhorn"
    kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
    kubectl label node $(hostname) node.longhorn.io/create-default-disk=true
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
}

set_airflow_worker_processes() {
    echo "[+] Setting Airflow worker processes to 2"
    kubectl patch deployment airflow-api-server -n airflow \
  --type='json' \
  -p='[
    {"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["airflow", "api-server", "--workers", "2"]}
  ]'
}

# Function to expose the Airflow API server
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
              value: "http://mlflow-server.mlflow.svc.cluster.local:5000"
            - name: AWS_ACCESS_KEY_ID
              value: ""
            - name: AWS_SECRET_ACCESS_KEY
              value: ""
            - name: AWS_DEFAULT_REGION
              value: "us-east-1"
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
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
      nodePort: 30081
EOF

    kubectl apply -f $APP_HOME/mlflow/mlflow-pvc.yaml
    kubectl apply -f $APP_HOME/mlflow/mlflow-deployment.yaml
    kubectl apply -f $APP_HOME/mlflow/mlflow-service.yaml
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

# Taint control-plane nodes
taint_nodes

# Install Cilium CNI
install_cilium

# Wait for Kubernetes nodes to be ready
wait_for_kubernetes_nodes

# Install Longhorn
install_longhorn

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

# Install other services (Inference server, etc.)

echo "[+] Kubernetes cluster setup complete."
