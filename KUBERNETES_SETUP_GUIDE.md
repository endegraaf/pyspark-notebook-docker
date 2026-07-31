# PySpark on Kubernetes Scaling Setup Guide

This guide explains step-by-step how we scaled this PySpark Jupyter repository from a single local Docker container into a **distributed PySpark cluster running on Kubernetes** on your Windows 11 Desktop.

---

## 1. Overview: What We Built & Why

### The Original Setup (Single Container)
Previously, the project ran via `docker-compose.yml`, which launched a single Docker container containing both Jupyter and PySpark running in local mode. While simple, it could only use the resources of that one container on a single node.

### The New Architecture (Spark-on-Kubernetes)
We transformed the setup into **Native Spark on Kubernetes**. Here is how it works under the hood:

```
                                  Windows 11 Machine
  +--------------------------------------------------------------------------------+
  |                                                                                |
  |  Browser ---> http://localhost:8888                                             |
  |                      |                                                         |
  |                      v                                                         |
  |         +------------------------- Kubernetes -------------------------------+ |
  |         |                                                                    | |
  |         |  +---------------------------------------------------------------+ | |
  |         |  |                    Jupyter Driver Pod                         | | |
  |         |  |               (Namespace: spark, Port: 8888)                  | | |
  |         |  |  - Runs JupyterLab interface                                  | | |
  |         |  |  - PySpark requests executors from K8s API                    | | |
  |         |  +-------------------------------+-------------------------------+ | |
  |         |                                  |                                 | |
  |         |                                  v (K8s API)                       | |
  |         |                 +---------------------------------+                | |
  |         |                 |    Dynamic Spark Executor Pods  |                | |
  |         |                 | +--------------+ +------------+ |                | |
  |         |                 | | spark-exec-1 | |spark-exec-2| |                | |
  |         |                 | +--------------+ +------------+ |                | |
  |         |                 +---------------------------------+                | |
  |         +--------------------------------------------------------------------+ |
  +--------------------------------------------------------------------------------+
```

1. **Jupyter Driver Pod**: Runs JupyterLab and acts as the **Spark Driver**.
2. **Kubernetes Control Plane**: Receives requests from PySpark inside the driver pod to spin up worker executor pods dynamically on demand.
3. **Dynamic Executor Pods (`spark-exec-*`)**: Created automatically when a PySpark job runs, perform the distributed calculations in parallel, and scale back down when finished.

---

## 2. Step-by-Step Breakdown of Changes Made

### Step 1: Created Kubernetes Infrastructure Manifests (`k8s/` Folder)

We created a set of Kubernetes manifest files in the `k8s/` directory to manage cluster resources:

*   **[k8s/namespace.yaml](file:///c:/GIT/pyspark-notebook-docker/k8s/namespace.yaml)**:
    Creates a dedicated `spark` namespace to isolate our PySpark workload from system Kubernetes pods.

*   **[k8s/rbac.yaml](file:///c:/GIT/pyspark-notebook-docker/k8s/rbac.yaml)**:
    Defines a `ServiceAccount` named `spark-driver` with `Role` permissions (`pods`, `services`, `configmaps`). This grants the Jupyter pod security rights to spawn and delete worker executor pods via the Kubernetes API.

*   **[k8s/pvc.yaml](file:///c:/GIT/pyspark-notebook-docker/k8s/pvc.yaml)**:
    Creates a 2GB `PersistentVolumeClaim` (`notebook-pvc`) so notebooks saved inside `/home/jovyan/work` persist even if pods restart.

*   **[k8s/spark-defaults-configmap.yaml](file:///c:/GIT/pyspark-notebook-docker/k8s/spark-defaults-configmap.yaml)**:
    Configures default Spark settings, such as:
    - Master URL: `k8s://https://kubernetes.default.svc:443`
    - Namespace: `spark`
    - ServiceAccount: `spark-driver`
    - Dynamic allocation bounds: min 1 executor, max 5 executors.

*   **[k8s/jupyter-deployment.yaml](file:///c:/GIT/pyspark-notebook-docker/k8s/jupyter-deployment.yaml)**:
    Defines the Jupyter Driver Pod Deployment and a **`LoadBalancer`** Service. The `LoadBalancer` type tells Docker Desktop to automatically expose `localhost:8888` (Jupyter) and `localhost:4040` (Spark UI) to your Windows host.

---

### Step 2: Updated Container Image & Dockerfile

We updated the **[Dockerfile](file:///c:/GIT/pyspark-notebook-docker/Dockerfile)** to ensure user permissions (`jovyan` user UID/GID) and working directory paths `/home/jovyan/work` are correctly configured for running inside Kubernetes pods.

---

### Step 3: Resolved Connection & Port Issues

When testing `http://localhost:8888`, we encountered two initial hurdles:

1. **Port Collision**: The old single-node container (`pyspark-notebook-docker-spark-app-1`) from Docker Compose was still running and occupying port 8888 on localhost.
   - *Fix*: Ran `docker compose down` to free up host port 8888.
2. **Kubernetes Port Binding**: A standard Kubernetes `ClusterIP` service is isolated inside the cluster network.
   - *Fix*: Switched the Kubernetes Service type in `k8s/jupyter-deployment.yaml` to `LoadBalancer`. Docker Desktop Kubernetes binds `LoadBalancer` ports directly to Windows `localhost`.

---

### Step 4: Built Kubernetes Example Notebook

We created a dedicated notebook: **[Notebook/k8s_spark_example.ipynb](file:///c:/GIT/pyspark-notebook-docker/Notebook/k8s_spark_example.ipynb)** demonstrating:
- Connecting `SparkSession` to the Kubernetes API (`k8s://https://kubernetes.default.svc:443`).
- Parallel computation (Monte Carlo Pi estimation across 100M samples).
- GroupBy and repartitioning aggregations across dynamic executor pods.

---

## 3. Useful Commands for Daily Use

Here are handy commands you can run in PowerShell for managing your Kubernetes PySpark setup:

### Deploying the Cluster
```powershell
# Deploy all Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
```

### Monitoring Executor Pods in Real-Time
```powershell
# Watch pods scale up/down in the 'spark' namespace
kubectl get pods -n spark -w
```

### Checking Logs
```powershell
# View Jupyter pod logs
kubectl logs -n spark deployment/jupyter-notebook -f
```

### Deleting the Kubernetes Cluster Resources
```powershell
# Remove all resources from Kubernetes
kubectl delete -f k8s/
```

---

## 4. How to Verify It's Working Now

1. Open your browser to **[http://localhost:8888/lab](http://localhost:8888/lab)**.
2. Open `Notebook/k8s_spark_example.ipynb`.
3. Run the cells in Jupyter.
4. While the notebook is running, execute `kubectl get pods -n spark` in PowerShell or inspect K9s to watch Spark dynamically spawn `spark-exec-*` pods!
