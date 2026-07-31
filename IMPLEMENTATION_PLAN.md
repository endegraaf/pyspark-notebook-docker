# Kubernetes Scaling Plan for PySpark Setup

This plan details how to scale the PySpark notebook environment using **Kubernetes (K8s)**. We will implement **Native Spark on Kubernetes**, where PySpark dynamically provisions and tears down executor pods on your K8s cluster as jobs require, as well as providing standalone Spark cluster manifests for fixed capacity.

## Architecture Overview

```
                      +---------------------------------------+
                      |         Kubernetes Cluster            |
                      |                                       |
 +------------------+ | +-----------------------------------+ |
 |   User Browser   | | |      Jupyter Driver Pod           | |
 | (http://localhost|---> (Port 8888)                           | |
 |     :8888)       | | |  PySpark app requests executors   | |
 +------------------+ | +-----------------+-----------------+ |
                      |                   |                   |
                      |                   v (K8s API)         |
                      |    +-----------------------------+    |
                      |    |   Dynamic Spark Executors   |    |
                      |    | +---------+  +------------+ |    |
                      |    | |Exec Pod1|  | Exec Pod2  | |    |
                      |    +-----------------------------+    |
                      +---------------------------------------+
```

## Local Testing on Windows 11 Desktop

To test and develop with this Kubernetes PySpark setup on a Windows 11 machine without cloud costs, you can use **Docker Desktop Kubernetes** or **Minikube**.

### Option A: Docker Desktop for Windows 11 (Recommended)
1. **Enable Kubernetes in Docker Desktop**:
   - Open **Docker Desktop** -> Settings (gear icon) -> **Kubernetes**.
   - Check **Enable Kubernetes** and click **Apply & restart**.
2. **Verify `kubectl` access**:
   ```powershell
   kubectl cluster-info
   kubectl get nodes
   ```
3. **Build image locally** (no external container registry needed):
   ```powershell
   docker build -t pyspark-notebook-k8s:latest .
   ```
4. **Deploy K8s manifests**:
   ```powershell
   kubectl apply -f k8s/
   ```
5. **Access Jupyter & Spark UI via Port Forwarding**:
   ```powershell
   # Forward Jupyter Notebook UI
   kubectl port-forward -n spark svc/jupyter-service 8888:8888
   
   # Forward Spark Driver UI
   kubectl port-forward -n spark svc/jupyter-service 4040:4040
   ```
6. Open browser at `http://localhost:8888` and run `Notebook/k8s_spark_example.ipynb`.

---

### Option B: Minikube on Windows 11 (WSL2 / Docker driver)
1. **Start Minikube**:
   ```powershell
   minikube start --driver=docker
   ```
2. **Build Docker image inside Minikube**:
   ```powershell
   minikube image build -t pyspark-notebook-k8s:latest .
   ```
3. **Deploy & Access**:
   ```powershell
   kubectl apply -f k8s/
   minikube service jupyter-service -n spark
   ```

---

## User Review Required

> [!IMPORTANT]
> **Local vs Remote Kubernetes**
> The Windows 11 instructions above allow testing entirely on your local machine using Docker Desktop Kubernetes or Minikube without needing an external image registry. Let us know if you prefer Docker Desktop or Minikube as your primary local environment!

## Proposed Changes

### 1. Docker & Build Configuration

#### [MODIFY] [Dockerfile](file:///c:/GIT/pyspark-notebook-docker/Dockerfile)
- Adapt image so it contains both Jupyter and PySpark runtime binaries compatible with Spark-on-K8s executor entrypoints.
- Set `imagePullPolicy: IfNotPresent` for local Windows testing without registry authentication.
- Ensure correct permissions for the `jovyan` user when running inside Kubernetes pods.

---

### 2. Kubernetes Manifests (`k8s/` Directory)

#### [NEW] [k8s/namespace.yaml](file:///c:/GIT/pyspark-notebook-docker/k8s/namespace.yaml)
- Define a dedicated `spark` namespace for isolated workload management.

#### [NEW] [k8s/rbac.yaml](file:///c:/GIT/pyspark-notebook-docker/k8s/rbac.yaml)
- Define `ServiceAccount` (`spark-driver`), `Role`, and `RoleBinding` granting the Jupyter driver pod permission to spawn, inspect, and delete executor pods (`pods`, `services`, `configmaps`).

#### [NEW] [k8s/pvc.yaml](file:///c:/GIT/pyspark-notebook-docker/k8s/pvc.yaml)
- Create a `PersistentVolumeClaim` to persist notebook files (`/home/jovyan/work`) across pod restarts.

#### [NEW] [k8s/jupyter-deployment.yaml](file:///c:/GIT/pyspark-notebook-docker/k8s/jupyter-deployment.yaml)
- Kubernetes Deployment and Service exposing Jupyter (port 8888) and Spark UI (port 4040).
- Uses `spark-driver` ServiceAccount.

#### [NEW] [k8s/spark-defaults-configmap.yaml](file:///c:/GIT/pyspark-notebook-docker/k8s/spark-defaults-configmap.yaml)
- ConfigMap containing default Spark K8s properties (`spark.master=k8s://https://kubernetes.default.svc:443`, memory/CPU defaults, namespace).

---

### 3. Notebook Examples

#### [NEW] [Notebook/k8s_spark_example.ipynb](file:///c:/GIT/pyspark-notebook-docker/Notebook/k8s_spark_example.ipynb)
- Interactive notebook demonstrating:
  - Initializing `SparkSession` with K8s master URL (`k8s://https://kubernetes.default.svc`).
  - Configuring dynamic allocation (`spark.dynamicAllocation.enabled=true`) for automatic pod autoscaling.
  - Monitoring active executor pods in the cluster via `kubectl get pods -n spark`.

---

### 4. Documentation & Windows Setup Scripts

#### [MODIFY] [README.md](file:///c:/GIT/pyspark-notebook-docker/README.md)
- Add complete step-by-step guide for Windows 11 (Docker Desktop & Minikube).
- Provide PowerShell helper commands to deploy, test, monitor (`kubectl get pods -w -n spark`), and tear down.

## Verification Plan

### Automated & Manual Verification
1. **Local Windows 11 Cluster**: Verify `kubectl cluster-info` on Windows 11 PowerShell.
2. **Manifest Validation**: Validate K8s YAML files using `kubectl apply --dry-run=client -f k8s/`.
3. **Pod Launch**: Verify `jupyter-notebook` pod starts successfully in K8s namespace on Docker Desktop / Minikube.
4. **Dynamic Pod Scaling**: Execute `Notebook/k8s_spark_example.ipynb` and observe Spark dynamically launching executor pods (`spark-exec-*`) in the Kubernetes cluster.
5. **Clean Teardown**: Verify dynamic executor cleanup after job completion.
