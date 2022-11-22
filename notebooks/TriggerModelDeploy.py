# Databricks notebook source
##################################################################################
# Helper notebook to trigger a model deployment workflow in CD. This notebook is run
# after the Train.py notebook as part of a multi-task job, in order to trigger model
# deployment after training completes.
#
# Note that we deploy the model to the stage in MLflow Model Registry equivalent to the
# environment in which the multi-task job is executed (e.g deploy the trained model to
# stage=Production if triggered in the prod environment). In a practical setting,
# we would recommend an intermediate step, such as compliance checks between
# model training and automatically registering the model to the Production stage in prod.
#
# This notebook has the following parameters:
#
#  * env (required)  - String name of the current environment for model deployment
#                      (staging, or prod)
#  * model_uri (required)  - URI of the model to deploy. Must be in the format "models:/<name>/<version-id>", as described in
#                            https://www.mlflow.org/docs/latest/model-registry.html#fetching-an-mlflow-model-from-the-model-registry
#                            This parameter is read as a task value
#                            (https://learn.microsoft.com/azure/databricks/dev-tools/databricks-utils#get-command-dbutilsjobstaskvaluesget),
#                            rather than as a notebook widget. That is, we assume a preceding task (the Train.py
#                            notebook) has set a task value with key "model_uri".
##################################################################################


# List of input args needed to run the notebook as a job.
# Provide them via DB widgets or notebook arguments.
#
# Name of the current environment
dbutils.widgets.dropdown("env", "None", ["None", "staging", "prod"], "Environment Name")

# COMMAND ----------
import sys

sys.path.append("../steps")

# COMMAND ----------
env = dbutils.widgets.get("env")
model_uri = dbutils.jobs.taskValues.get("Train", "model_uri", debugValue="")
assert env != "None", "env notebook parameter must be specified"
assert model_uri != "", "model_uri notebook parameter must be specified"

# COMMAND ----------
from deploy import deploy
# TODO: Add any additional pre-deployment checks here to ensure model quality before calling
# `deploy` to push the model to the desired environment.
deploy(model_uri, env)

# COMMAND ----------
print(
    f"Successfully triggered model deployment workflow for {model_uri}"
)
