import pendulum
from datetime import datetime
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
import sys
sys.path.insert(0, '/dev_mm')

local_tz = pendulum.timezone("utc")

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email': ['name@companymail.ru'],
    'email_on_failure': True,
    'email_on_success': False,
    'retries': 1,
    'start_date': datetime(2024,2,2,15,tzinfo = local_tz)
}

dag = DAG(
    dag_id='alert_topup',
    catchup=False,
    default_args=default_args,
    schedule_interval='0 7 * * *'
)

task = BashOperator(
    task_id='alert_topup',
    dag = dag,
    bash_command="export PYTHONPATH=/dev_analit;/opt/anaconda/envs/py37/bin/python -u /dev_analit/reports/alert_topup.py"
)