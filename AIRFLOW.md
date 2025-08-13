https://chatgpt.com/share/68823e69-3bbc-800a-bb23-f2e068a1e13d

https://chatgpt.com/share/68823e17-7cfc-800a-9718-6491e1fc6a5d

New chat detected.. initialising summary generation mode 🧠

---

## 🚀 Airflow on Kubernetes — Deployment Summary (July 2025)

You've orchestrated a complex yet functional **Apache Airflow deployment on a single-node Kubernetes cluster** using `kubeadm`. Below is a concise but complete summary of what’s been achieved and debugged so far:

---

### 🏗️ Cluster Setup

* **Provisioned a single-node Kubernetes cluster** via `kubeadm` on an Ubuntu instance.
* Installed and configured:

  * Docker / containerd with `SystemdCgroup`
  * Kubernetes components: `kubeadm`, `kubelet`, `kubectl`
  * Helm (for package management)
  * Longhorn (for dynamic volume provisioning)
* Configured system:

  * Disabled swap
  * Tuned `sysctl` for Kubernetes networking
  * Setup proper kubeconfig for kubectl access

---

### 📦 Deployed Components

#### ✅ Helm charts used:

* **Apache Airflow** (`apache-airflow/airflow`)
* **Longhorn** (official GitHub manifests)
* **Prometheus repo** (added for possible future metrics)

#### 🛠️ Custom Helm `values.yaml`:

* **Executor:** `CeleryExecutor`
* **PostgreSQL:** Enabled with persistent volume via Longhorn
* **Redis:** Enabled with persistence
* **GitSync DAGs:** From GitHub repo `Lay-ke/MLOps-Project`
* **Log persistence:** Enabled with Longhorn
* **User auth:** Default web login via `admin:admin`
* **Disabled Flower UI** to avoid port conflicts

---

### ⚠️ Key Issues Resolved

* 🔒 `kubectl get nodes` failed due to missing `admin.conf` setup — fixed by manually exporting kubeconfig.
* 📦 Airflow pods stuck in `Init` due to **Longhorn mount errors** (missing NFS helper or Longhorn not fully ready).
* 🔁 `airflow-scheduler` and `airflow-api-server` containers stuck in **startupProbe failure** loop.
* 🛠️ Temporary fixes:

  * Increased startup probe timeout
  * Verified secrets/envs are injected correctly
  * Checked Airflow DB readiness
* 🌐 Longhorn UI access exposed using `NodePort` due to cloud LoadBalancer unavailability.

---

### 📉 Outstanding Issues / Improvements

* Startup time of custom image (`mintah/airflow-custom`) is long — consider optimizing.
* You encountered `state mismatch` on task status — suggests **Celery workers** or **DB backend** may be out of sync.
* Scheduler probe often fails on first boot — needs better resilience or cold-start handling.
* DAGs from GitSync not confirmed as synced yet — verify with `kubectl logs airflow-worker-*`.

---

### 🧪 Optional Next Steps

* Replace kubeadm with Minikube (you already considered this)
* Set up Airflow with KubernetesExecutor for simpler infra
* Add observability: Prometheus + Grafana
* Auto-recovery & self-healing via better probes/liveness tweaks

---

You’ve covered a **huge range of infra and Airflow internals** — solid foundation to scale or iterate. Let me know if you want this in markdown, Confluence-ready, or just prettified text.


# 2
📘 **Airflow Helm Deployment Progress Documentation**

---

### 🎯 **Objective**

Deploy **Apache Airflow 3.0.x** with **CeleryExecutor** on Kubernetes using Helm, persistent volumes via **Longhorn**, and a **custom Docker image** for the API server.

---

### ✅ **Steps Completed**

#### 1. **Initial Helm Deployment**

* Used official Helm chart from Apache:

  ```
  helm repo add apache-airflow https://airflow.apache.org
  helm repo update
  ```
* Initial `values.yaml` configured:

  * `executor: CeleryExecutor`
  * PVC-backed DAGs/logs using `longhorn`
  * Enabled Redis, PostgreSQL, Flower UI
  * Created default admin user

#### 2. **Custom Docker Image**

* Built & pushed custom image: `jili/airflow:3.0.0-fixed`

  * Purpose: Fix missing `airflow.www` module for `api-server`
  * Base image: `apache/airflow:3.0.x`

#### 3. **Upgrade Helm Release**

* Initial upgrade attempt failed to override image:

  * Incorrect `image:` key used in `values.yaml`
* Fixed using:

  ```yaml
  images:
    airflow:
      repository: jili/airflow
      tag: 3.0.0-fixed
  ```
* Re-installed with:

  ```bash
  helm uninstall airflow -n airflow
  helm install airflow apache-airflow/airflow \
    --namespace airflow \
    --create-namespace \
    --values fixed-values.yaml
  ```

#### 4. **Observed Issues**

* Pods stuck in `CrashLoopBackOff`
* Logs showed `airflow.www` missing → fixed in custom image
* Some deployments still pulled `apache/airflow:3.0.2` due to override mismatch

---

### 🧪 **Troubleshooting**

* Used:

  ```bash
  kubectl describe pod ...
  kubectl logs ...
  ```
* Verified image via:

  ```bash
  kubectl get pods -n airflow -o jsonpath="{.items[*].spec.containers[*].image}"
  ```

---

### 🧱 **Next Steps**

* Confirm all pods use `jili/airflow:3.0.0-fixed`
* Monitor startup probe failures
* Verify Airflow UI and API availability
* Optionally push image to a private registry with version lock

---

