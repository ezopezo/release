#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail
set -o verbose

OCM_ENV=$API_HOST
SET_ENVIRONMENT="1"
OC_HOST=$(oc whoami --show-server)
CLUSTER_ID=$(cat "${SHARED_DIR}/cluster-id")
CLUSTER_NAME=$(cat "${SHARED_DIR}/cluster-name")
OCM_TOKEN=$(cat /var/run/secrets/ci.openshift.io/cluster-profile/ocm-token)
ROBOT_EXTRA_ARGS="-i $TEST_MARKER -e AutomationBug -e Resources-GPU -e Resources-2GPUS"
RUN_SCRIPT_ARGS="--skip-oclogin true --set-urls-variables true --test-artifact-dir ${ARTIFACT_DIR}/results"

export OCM_ENV
export SET_ENVIRONMENT
export OC_HOST
export CLUSTER_NAME
export OCM_TOKEN
export ROBOT_EXTRA_ARGS
export RUN_SCRIPT_ARGS

mkdir $ARTIFACT_DIR/results

# delete IDPs before running testsuite
if [ "${API_HOST}" = "stage" ]; then
    API_URL=https://api.stage.openshift.com/
else
    API_URL=https://api.openshift.com/
fi
ocm login --url=$API_URL --token=$OCM_TOKEN
for IDP in $(ocm get /api/clusters_mgmt/v1/clusters/$CLUSTER_ID/identity_providers | jq -r '.items[].name'); do
  ocm delete idp $IDP --cluster=$CLUSTER_ID
done

# running RHODS testsuite
./ods_ci/build/run.sh
