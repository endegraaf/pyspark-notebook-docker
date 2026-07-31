# PySpark Jupyter Notebook with Docker & Kubernetes

This repository provides a complete setup to run and scale a PySpark environment within a Jupyter Notebook using Docker and **Kubernetes (K8s)**. It supports both quick local development via Docker Compose and distributed autoscaling via native Spark on Kubernetes.

## Features

*   **Dockerized Environment**: Containerized PySpark and Jupyter environment for consistency and portability.
*   **Kubernetes Scaling**: Dynamically spawn and autoscale Spark executor pods on a K8s cluster (Docker Desktop K8s, Minikube, EKS, GKE, AKS). See [KUBERNETES_SETUP_GUIDE.md](file:///c:/GIT/pyspark-notebook-docker/KUBERNETES_SETUP_GUIDE.md) for step-by-step technical details.
*   **Interactive Notebooks**: Includes `hello-world.ipynb` and `k8s_spark_example.ipynb`.
*   **Spark UI**: Integrated monitoring at `http://localhost:4040`.

---

## Deployment Options

### Option 1: Kubernetes Distributed Scaling (Recommended for Scaling)

#### Prerequisites
*   [Docker Desktop](https://docs.docker.com/get-docker/) (with Kubernetes enabled) or [Minikube](https://minikube.sigs.k8s.io/).
*   `kubectl` CLI tool.

#### Step 1: Build the Docker Image
Build the container image locally so Kubernetes can use it:
```powershell
docker build -t pyspark-notebook-k8s:latest .
```
*(If using Minikube, run `minikube image build -t pyspark-notebook-k8s:latest .` instead).*

#### Step 2: Deploy Kubernetes Manifests
Apply the Kubernetes configuration files in order:
```powershell
# Create dedicated namespace
kubectl apply -f k8s/namespace.yaml

# Apply RBAC, PVC, ConfigMap, and Jupyter Deployment
kubectl apply -f k8s/rbac.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/spark-defaults-configmap.yaml
kubectl apply -f k8s/jupyter-deployment.yaml
```

#### Step 3: Access Jupyter & Spark UI
Forward ports from the Jupyter driver pod to your local machine:
```powershell
# Port forward Jupyter Notebook UI (8888) and Spark UI (4040)
kubectl port-forward -n spark svc/jupyter-service 8888:8888 4040:4040
```
Open your browser at:
*   **Jupyter Notebook**: `http://localhost:8888`
*   **Spark Application UI**: `http://localhost:4040`

#### Step 4: Run the Kubernetes Scaling Notebook
Inside Jupyter, open `k8s_spark_example.ipynb`. As jobs execute, inspect the dynamic executor pods created by Spark:
```powershell
kubectl get pods -n spark -w
```

---

### Option 2: Standalone Local Development (Docker Compose)

For simple local development without Kubernetes:

#### Step 1: Launch Container
```powershell
docker compose up -d
```

#### Step 2: Access Jupyter
Navigate to `http://localhost:8888` in your browser.

#### Step 3: Teardown
```powershell
docker compose down
```

---

## Project Structure

```
├── Dockerfile                      # Container definition for Jupyter Driver & Spark Executors
├── docker-compose.yml              # Docker Compose setup for local single-node testing
├── requirements.txt                # Python package dependencies
├── k8s/
│   ├── namespace.yaml              # 'spark' Kubernetes namespace
│   ├── rbac.yaml                   # ServiceAccount & RBAC rules for dynamic executor creation
│   ├── pvc.yaml                    # Persistent volume claim for notebooks persistence
│   ├── spark-defaults-configmap.yaml # Default Spark K8s properties
│   └── jupyter-deployment.yaml     # Jupyter Driver Pod deployment & service
├── Notebook/
│   ├── hello-world.ipynb           # Basic PySpark test notebook
│   └── k8s_spark_example.ipynb     # Distributed Spark on K8s benchmark & scaling notebook
├── IMPLEMENTATION_PLAN.md          # Technical scaling & implementation details
└── README.md                       # Documentation & deployment guide
```

## Stopping the Kubernetes Cluster

To remove all resources deployed to Kubernetes:
```powershell
kubectl delete -f k8s/
```