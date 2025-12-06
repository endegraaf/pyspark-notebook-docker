# Use the official image that already has Spark, Java, and Python configured
FROM jupyter/pyspark-notebook:x86_64-python-3.11

# Switch to root user temporarily to install extra packages
USER root

# Copy requirements and install them
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Switch back to the standard user 'jovyan' (required by this image)
USER ${NB_UID}

# Expose the standard ports
EXPOSE 8888
EXPOSE 4040