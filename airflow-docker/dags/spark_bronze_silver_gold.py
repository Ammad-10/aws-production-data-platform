# Phase 4: EMR on EKS / S3 / Glue - bronze -> silver -> gold pipeline
# Set Airflow Variables: DATA_LAKE_BUCKET, GLUE_DATABASE, EMR_VIRTUAL_CLUSTER_ID, EMR_JOB_EXECUTION_ROLE_ARN
# (Get EMR_VIRTUAL_CLUSTER_ID and EMR_JOB_EXECUTION_ROLE_ARN from: terraform output -raw emr_virtual_cluster_id / emr_job_execution_role_arn)
# When use_emr_on_eks is false, pause this DAG or set vars once EMR is enabled.

from airflow import DAG
from airflow.models import Variable
from airflow.utils.dates import days_ago
from airflow.providers.amazon.aws.operators.emr import EmrContainerOperator

default_args = {
    "owner": "data-platform",
    "depends_on_past": False,
    "retries": 1,
}


def _spark_job_driver(step: str):
    """Spark submit job driver for EMR on EKS. Replace entryPoint with your Spark script path in the image."""
    return {
        "sparkSubmitJobDriver": {
            "entryPoint": "local:///usr/lib/spark/examples/src/main/python/pi.py",
            "sparkSubmitParameters": (
                "--conf spark.executors.instances=2 "
                "--conf spark.executors.memory=2G "
                "--conf spark.driver.cores=1"
            ),
        }
    }


with DAG(
    dag_id="spark_bronze_silver_gold",
    default_args=default_args,
    schedule_interval=None,
    start_date=days_ago(1),
    tags=["emr", "spark", "data-lake"],
) as dag:
    bucket = Variable.get("DATA_LAKE_BUCKET", default_var="data-platform-datalake-dev")
    glue_db = Variable.get("GLUE_DATABASE", default_var="data_lake_dev")
    virtual_cluster_id = Variable.get("EMR_VIRTUAL_CLUSTER_ID", default_var="")
    job_role_arn = Variable.get("EMR_JOB_EXECUTION_ROLE_ARN", default_var="")

    bronze = EmrContainerOperator(
        task_id="bronze",
        virtual_cluster_id=virtual_cluster_id,
        job_driver=_spark_job_driver("bronze"),
        release_label="emr-6.10.0-latest",
        job_role_arn=job_role_arn,
        name="bronze-{{ ds_nodash }}",
        execution_timeout=3600,
    )
    silver = EmrContainerOperator(
        task_id="silver",
        virtual_cluster_id=virtual_cluster_id,
        job_driver=_spark_job_driver("silver"),
        release_label="emr-6.10.0-latest",
        job_role_arn=job_role_arn,
        name="silver-{{ ds_nodash }}",
        execution_timeout=3600,
    )
    gold = EmrContainerOperator(
        task_id="gold",
        virtual_cluster_id=virtual_cluster_id,
        job_driver=_spark_job_driver("gold"),
        release_label="emr-6.10.0-latest",
        job_role_arn=job_role_arn,
        name="gold-{{ ds_nodash }}",
        execution_timeout=3600,
    )
    bronze >> silver >> gold
