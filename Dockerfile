# Use the official PySpark Jupyter Notebook image
FROM jupyter/pyspark-notebook:x86_64-python-3.11

# Switch to root user to configure environment and permissions
USER root

# Copy requirements and install them
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Ensure jovyan user has write permissions in working directory
RUN chown -R ${NB_UID}:${NB_GID} /home/jovyan/work

# Switch back to jovyan user
USER ${NB_UID}

# Expose standard Jupyter and Spark UI ports
EXPOSE 8888
EXPOSE 4040