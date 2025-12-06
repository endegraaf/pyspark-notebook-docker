# PySpark Jupyter Notebook with Docker

This repository provides a straightforward setup to run a PySpark environment within a Jupyter Notebook using Docker. It's designed for developers and data scientists who want to get started with PySpark quickly without complex local installations.

The configuration uses a Docker image that includes Spark and Jupyter, allowing you to focus on your data analysis tasks. [9]

## Features

*   **Dockerized Environment**: Encapsulates the entire environment for consistency and portability.
*   **Jupyter Notebook**: Provides an interactive web-based interface for writing and running code. [14]
*   **Apache Spark**: Comes with Spark ready to be used for big data processing.
*   **Easy Setup**: Get up and running with just a couple of terminal commands.

## Prerequisites

Before you begin, ensure you have the following installed on your system:
*   [Docker](https://docs.docker.com/get-docker/)
*   [Docker Compose](https://docs.docker.com/compose/install/)

## Getting Started

Follow these steps to launch the PySpark notebook environment.

### 1. Clone the Repository (Optional)

If you have this `docker-compose.yml` as part of a git repository, clone it first. Otherwise, just make sure you are in the same directory as the `docker-compose.yml` file.

### 2. Launch the Environment

Open your terminal, navigate to the project directory, and run the following command:

```bash
docker-compose up -d
```

This command builds the Docker image and starts the container in detached mode.

### 3. Access Jupyter Notebook

Once the container is running, open your web browser and navigate to:

`http://localhost:8888`

You will see the Jupyter Notebook interface. No token or password is required as it is disabled in the configuration for ease of access. [1]

### 4. Access the Spark UI

To monitor your Spark jobs, the Spark UI is available at:

`http://localhost:4040`

### 5. Your Notebooks

The `Notebook` folder in your local project directory is mapped to the working directory inside the container (`/home/jovyan/work`). Any Jupyter notebook files (`.ipynb`) you create or place in the `Notebook` folder will be accessible within the Jupyter interface. [4]

## Stopping the Environment

To stop and remove the running containers, execute the following command in your terminal:

```bash
docker-compose down
```