#!/bin/bash

set -e

NAMESPACE="${K8S_NAMESPACE:-karan-dashboard}"

SERVICE_NAME="karan-devops-dashboard-service"

LOCAL_PORT="5050"

SERVICE_PORT="5000"

APP_URL="http://localhost:${LOCAL_PORT}/health"

PORT_FORWARD_LOG="${WORKSPACE:-/tmp}/karan-health-port-forward.log"

echo "=========================================="
echo "Karan DevOps Dashboard Health Check"
echo "=========================================="

echo
echo "Namespace:    $NAMESPACE"
echo "Service:      $SERVICE_NAME"
echo "Local Port:   $LOCAL_PORT"
echo "Service Port: $SERVICE_PORT"
echo

# --------------------------------------------------
# 1. Check Kubernetes Pods
# --------------------------------------------------

echo "1. Checking Kubernetes pods..."

kubectl get pods \
    -n "$NAMESPACE"

echo

# --------------------------------------------------
# 2. Check Kubernetes Service
# --------------------------------------------------

echo "2. Checking Kubernetes service..."

kubectl get svc \
    "$SERVICE_NAME" \
    -n "$NAMESPACE"

echo

# --------------------------------------------------
# 3. Stop existing port-forward
# --------------------------------------------------

echo "3. Stopping existing port-forward if running..."

pkill -f \
    "kubectl port-forward.*${SERVICE_NAME}" \
    || true

sleep 2

# --------------------------------------------------
# 4. Start port-forward
# --------------------------------------------------

echo "4. Starting Kubernetes port-forward..."

nohup kubectl port-forward \
    "svc/${SERVICE_NAME}" \
    "${LOCAL_PORT}:${SERVICE_PORT}" \
    -n "$NAMESPACE" \
    > "$PORT_FORWARD_LOG" 2>&1 &

PORT_FORWARD_PID=$!

echo "Port-forward PID: $PORT_FORWARD_PID"

# --------------------------------------------------
# 5. Wait for application
# --------------------------------------------------

echo
echo "5. Waiting for application..."

HEALTH_CHECK_PASSED=false

for i in {1..15}
do

    if curl -sf \
        "$APP_URL" \
        > /tmp/karan-health-response.json
    then

        HEALTH_CHECK_PASSED=true

        echo
        echo "Health check passed."
        echo

        cat /tmp/karan-health-response.json

        break
    fi

    echo "Attempt $i/15 failed. Waiting 2 seconds..."

    sleep 2

done

# --------------------------------------------------
# 6. Handle health-check failure
# --------------------------------------------------

if [ "$HEALTH_CHECK_PASSED" = false ]; then

    echo
    echo "=========================================="
    echo "Health check FAILED."
    echo "=========================================="

    echo
    echo "Port-forward log:"
    cat "$PORT_FORWARD_LOG" || true

    echo
    echo "Kubernetes pods:"

    kubectl get pods \
        -n "$NAMESPACE" \
        -o wide \
        || true

    echo
    echo "Kubernetes service:"

    kubectl get svc \
        "$SERVICE_NAME" \
        -n "$NAMESPACE" \
        || true

    echo
    echo "Application pod details:"

    kubectl describe pods \
        -n "$NAMESPACE" \
        -l app=karan-devops-dashboard \
        || true

    exit 1

fi

# --------------------------------------------------
# 7. Success
# --------------------------------------------------

echo
echo "=========================================="
echo "Application is healthy."
echo "=========================================="

echo
echo "Application URL:"
echo "http://localhost:${LOCAL_PORT}"

echo
echo "Health URL:"
echo "$APP_URL"

echo
echo "Port-forward PID:"
echo "$PORT_FORWARD_PID"

echo
echo "=========================================="
