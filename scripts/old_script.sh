#!/bin/bash

# This script is used to setup single node Kubernetes cluster using kubeadm and Docker.

# Update the package index
sudo apt update && sudo apt upgrade -y

# Disable swap
# Kubernetes requires swap to be disabled
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Kernel modules for Kubernetes
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Install Docker
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Restart the Docker service
# sudo newgrp docker

# Change the cgroup driver to systemd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Add the Kubernetes APT repository
sudo apt install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | \
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signesudo apt install -y nfs-commond-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | \
sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update

# Install kubeadm, kubelet, and kubectl
sudo apt install -y kubeadm kubelet kubectl
sudo apt-mark hold kubeadm kubelet kubectl

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

sudo kubeadm init --pod-network-cidr=10.0.0.0/16

# Set up nfs-common for NFS support
sudo apt install -y nfs-common

# Wait until admin.conf exists
while [ ! -f /etc/kubernetes/admin.conf ]; do
  echo "Waiting for admin.conf to be generated..."
  sleep 5
done

ls /etc/kubernetes/
sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Install Cilium CNI 
curl -L --remote-name https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
sudo tar xzvf cilium-linux-amd64.tar.gz -C /usr/local/bin
rm cilium-linux-amd64.tar.gz

cilium install

kubectl get nodes

cat << EOF > fixed-values.yaml
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
    value: "QnsUOUt+"
  - name: AWS_DEFAULT_REGION
    value: "us-east-1"
  - name: MLFLOW_TRACKING_URI
    value: "http://mlflow-server.mlflow.svc.cluster.local:5000"
  - name: INFERENCE_API_URL
    value: "http://inference-service.inference.svc.cluster.local:8000"
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

kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
kubectl label node $(hostname) node.longhorn.io/create-default-disk=true

# sync dag in github to airflow issue resolved
kubectl -n kube-system patch configmap coredns \
  --type merge \
  -p '{
    "data": {
      "Corefile": ".:53 {\n    errors\n    health\n    ready\n    kubernetes cluster.local in-addr.arpa ip6.arpa {\n       pods insecure\n       fallthrough in-addr.arpa ip6.arpa\n       ttl 30\n    }\n    prometheus :9153\n    forward . 1.1.1.1 8.8.8.8\n    cache 30\n    loop\n    reload\n    loadbalance\n}"
    }
  }'

kubectl rollout restart deployment coredns -n kube-system

helm repo add apache-airflow https://airflow.apache.org
helm repo update

# chwck if nfs-common is installed
helm upgrade --install airflow apache-airflow/airflow \
  --namespace airflow \
  --create-namespace \
  --values fixed-values.yaml

# Wait for the pods to be ready
sleep 60



# Update the Airflow API server deployment to use a single worker
kubectl patch deployment airflow-api-server -n airflow \
  --type='json' \
  -p='[
    {"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["airflow", "api-server", "--workers", "1"]}
  ]'

# exposing api server
kubectl patch svc airflow-api-server -n airflow \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 8080, "targetPort": 8080, "protocol": "TCP", "nodePort": 30080}]}}'

sudo mkdir -p mlflow

cat << EOF > mlflow/mlflow-pvc.yaml
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

cat <<EOF > mlflow/mlflow-deployment.yaml
# mlflow-deployment.yaml
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
            - --backend-store-uri=sqlite:///mlflow.db
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
      resources:
        requests:
          memory: "512Mi"
          cpu: "250m"
        limits:
          memory: "1Gi"
          cpu: "500m"
EOF

cat <<EOF > mlflow/mlflow-service.yaml
# mlflow-service.yaml
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

kubectl create namespace mlflow
kubectl apply -f mlflow/mlflow-pvc.yaml
kubectl apply -f mlflow/mlflow-deployment.yaml
kubectl apply -f mlflow/mlflow-service.yaml

# mlflow service is reachable on: http://mlflow-server.mlflow.svc.cluster.local:5000
#inference service is reachable on: http://inference-service.inference.svc.cluster.local:8000

# Setting up inference server
sudo mkdir -p inference-server

cat <<EOF > inference-server/deployment-service.yaml
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
        image: mintah/inference-api:latest
        ports:
        - containerPort: 8000
        env:
        - name: AWS_ACCESS_KEY_ID
          value: ""
        - name: AWS_SECRET_ACCESS_KEY
          value: ""
        - name: MLFLOW_TRACKING_URI
          value: "http://mlflow-server.mlflow.svc.cluster.local:5000"
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

cat <<EOF > inference-server/nginx.yaml
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
kubectl create namespace inference
kubectl apply -f inference-server/

mkdir -p airflow-monitoring
cat <<EOF > airflow-monitoring/prometheus-values.yaml
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

cat <<EOF > airflow-monitoring/grafana-values.yaml
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

