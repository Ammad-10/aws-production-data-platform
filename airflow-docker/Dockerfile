# Custom Airflow image with DAGs; extend official image
FROM apache/airflow:2.8.0
USER airflow
# EmrContainerOperator and S3/Glue usage
RUN pip install --no-cache-dir "apache-airflow-providers-amazon>=8.0"
COPY --chown=airflow:root dags/ /opt/airflow/dags/
