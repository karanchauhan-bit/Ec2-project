#!/bin/bash

set -e


NAMESPACE="${K8S_NAMESPACE:-karan-dashboard}"

SERVICE_NAME="${K8S_SERVICE_NAME:-karan-devops-dashboard-service}"

LOCAL_PORT="${LOCAL_PORT:-5050}"

REMOTE_PORT=5000

MAX_ATTEMPTS=10

WAIT_SECONDS=3

TEMP_FILE="/tmp/karan-devops-health.json"

PORT_FORWARD_LOG="/tmp/karan-devops-port-forward.log"


echo "=========================================="

echo "Karan DevOps Dashboard Health Check"

echo "=========================================="


echo

echo "Waiting for Kubernetes Deployment..."


kubectl rollout status \
    deployment/karan-devops-dashboard \
    -n "$NAMESPACE" \
    --timeout=180s


echo

echo "Starting temporary port-forward..."


kubectl port-forward \
    "service/$SERVICE_NAME" \
    "$LOCAL_PORT:$REMOTE_PORT" \
    -n "$NAMESPACE" \
    >"$PORT_FORWARD_LOG" 2>&1 &


PORT_FORWARD_PID=$!


cleanup() {

    kill "$PORT_FORWARD_PID" \
        2>/dev/null \
        || true

    rm -f "$TEMP_FILE"
}


trap cleanup EXIT


echo "Checking application health..."


for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt++)); do

    echo "Attempt $attempt/$MAX_ATTEMPTS..."


    if curl \
        --silent \
        --show-error \
        --fail \
        --max-time 5 \
        "http://127.0.0.1:${LOCAL_PORT}/health" \
        -o "$TEMP_FILE"; then

        echo

        echo "Health endpoint response:"

        cat "$TEMP_FILE"

        echo

        echo

        echo "Health check passed."

        exit 0

    fi


    sleep "$WAIT_SECONDS"

done


echo

echo "Health check failed."


echo

echo "Port-forward log:"

cat "$PORT_FORWARD_LOG" \
    || true


exit 1
