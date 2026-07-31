# Scaling PySpark Docker Setup

This document outlines the architecture and changes required to scale the single-container PySpark Docker environment into a multi-container distributed Spark cluster locally (Master + Workers + Jupyter Notebook) as well as guidance for scaling to Kubernetes or Cloud providers.

## User Review Required

> [!IMPORTANT]
> **Scaling Approach Clarification**
> Please review the proposed local multi-node architecture below. If your primary goal is scaling to a cloud infrastructure (AWS EMR, Google Cloud Dataproc, Kubernetes, or Databricks) instead of local multi-worker container scaling, please let us know so we can tailor the deployment scripts and Helm/K8s manifests accordingly.

## Proposed Changes

### Docker Infrastructure & Cluster Architecture

#### [MODIFY] [docker-compose.yml](file:///c:/GIT/pyspark-notebook-docker/docker-compose.yml)
- Transform from single `spark-app` container to a multi-service architecture:
  1. `spark-master`: Dedicated Apache Spark Master node exposing port `7077` (Cluster Manager) and `8080` (Master Web UI).
  2. `spark-worker`: Scalable Spark Worker node exposing port `8081` (Worker Web UI), connected to `spark://spark-master:7077`. Configured to support multi-worker scaling (`docker compose up --scale spark-worker=3`).
  3. `jupyter-notebook`: Notebook environment (driver node) pre-configured to submit jobs to `spark://spark-master:7077`, with port `8888` (Jupyter) and `4040` (Spark Driver UI).
- Define a shared Docker network (`spark-network`) so containers communicate seamlessly.
- Set up shared volume mounts across workers and driver if local file sharing is required (`./Notebook` or shared volume).

#### [MODIFY] [Dockerfile](file:///c:/GIT/pyspark-notebook-docker/Dockerfile)
- Update/extend Dockerfile to ensure compatible Spark binary versions and PySpark versions across Master, Worker, and Jupyter Driver nodes.
- Expose required Spark cluster ports (`7077`, `8080`, `8081`, `8888`, `4040`).

---

### Notebook & SparkSession Configuration

#### [MODIFY] [Notebook/hello-world.ipynb](file:///c:/GIT/pyspark-notebook-docker/Notebook/hello-world.ipynb)
- Update notebook examples to demonstrate:
  - Connecting `SparkSession` to `spark://spark-master:7077`.
  - Configuring worker memory, executor cores, and dynamic allocation.
  - Verifying active worker nodes in the cluster through PySpark context.

#### [NEW] [Notebook/distributed_scaling_example.ipynb](file:///c:/GIT/pyspark-notebook-docker/Notebook/distributed_scaling_example.ipynb)
- Add a dedicated benchmark / distributed processing notebook demonstrating parallel data generation, partitioning (`repartition`), and worker utilization.

---

### Documentation & Production Scaling Guidelines

#### [MODIFY] [README.md](file:///c:/GIT/pyspark-notebook-docker/README.md)
- Document how to launch and scale the cluster locally (`docker compose up --scale spark-worker=N`).
- Document URLs for Spark Master UI (`localhost:8080`), Worker UI (`localhost:8081`), Jupyter (`localhost:8888`), and Spark Application UI (`localhost:4040`).
- Add a section on production scaling (Kubernetes/Helm, AWS EMR, GCP Dataproc) and cloud storage integration (S3/GCS/Azure Blob).

## Open Questions

> [!NOTE]
> 1. **Resource allocation**: How many CPU cores and RAM are available on your host machine for the local cluster (e.g., 2 workers with 2GB/2 cores each)?
> 2. **Target Deployment**: Is your goal local cluster development (Docker Compose multi-worker), production cloud deployment (Kubernetes / AWS / GCP), or both?

## Verification Plan

### Automated / Manual Verification
1. **Container Cluster Launch**: Run `docker compose up -d` and `docker compose up -d --scale spark-worker=2` to ensure Master and 2 Worker containers start without errors.
2. **Spark Master UI**: Check `http://localhost:8080` to verify that 2 worker nodes are registered with the Spark Master.
3. **Jupyter Job Execution**: Run `distributed_scaling_example.ipynb` in Jupyter (`http://localhost:8888`) connected to `spark://spark-master:7077` and verify task distribution across worker nodes in the Spark UI (`http://localhost:4040`).
