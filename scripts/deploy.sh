#!/bin/bash

set -e


NAMESPACE="${K8S_NAMESPACE:-karan-dashboard}"

IMAGE_REPO="${IMAGE_REPO:-YOUR_DOCKERHUB_USERNAME/karan-devops-dashboard}"

IMAGE_TAG="${IMAGE_TAG:-latest}"

MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-rootpassword}"

MYSQL_PASSWORD="${MYSQL_PASSWORD:-karanpassword}"


echo "=========================================="

echo "Karan DevOps Dashboard Kubernetes Deploy"

echo "=========================================="


echo

echo "Namespace: $NAMESPACE"

echo "Image:     $IMAGE_REPO:$IMAGE_TAG"

echo


if [[ "$IMAGE_REPO" == "YOUR_DOCKERHUB_USERNAME/"* ]]; then

    echo "ERROR: Replace YOUR_DOCKERHUB_USERNAME."

    exit 1

fi


echo "1. Applying namespace..."

kubectl apply \
    -f k8s/namespace.yaml


echo "2. Creating/updating MySQL secret..."

kubectl create secret generic \
    karan-mysql-secret \
    --namespace "$NAMESPACE" \
    --from-literal=MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    --from-literal=MYSQL_PASSWORD="$MYSQL_PASSWORD" \
    --dry-run=client \
    -o yaml \
    | kubectl apply -f -


echo "3. Applying ConfigMap..."

kubectl apply \
    -f k8s/configmap.yaml


echo "4. Applying MySQL storage..."

kubectl apply \
    -f k8s/mysql-pv.yaml

kubectl apply \
    -f k8s/mysql-pvc.yaml


echo "5. Applying MySQL Service..."

kubectl apply \
    -f k8s/mysql-service.yaml


echo "6. Applying MySQL Deployment..."

kubectl apply \
    -f k8s/mysql-deployment.yaml


echo "7. Waiting for MySQL PVC..."

kubectl wait \
    --for=jsonpath='{.status.phase}'=Bound \
    pvc/karan-mysql-pvc \
    -n "$NAMESPACE" \
    --timeout=120s


echo "8. Waiting for MySQL..."

kubectl rollout status \
    deployment/karan-mysql \
    -n "$NAMESPACE" \
    --timeout=180s


echo "9. Applying application Service..."

kubectl apply \
    -f k8s/app-service.yaml


echo "10. Applying application Deployment..."

sed \
    -e "s|IMAGE_REPOSITORY_PLACEHOLDER|${IMAGE_REPO}|g" \
    -e "s|IMAGE_TAG_PLACEHOLDER|${IMAGE_TAG}|g" \
    k8s/app-deployment.yaml \
    | kubectl apply -f -


echo "11. Waiting for application rollout..."

kubectl rollout status \
    deployment/karan-devops-dashboard \
    -n "$NAMESPACE" \
    --timeout=180s


echo

echo "=========================================="

echo "Deployment completed successfully."

echo "=========================================="


echo

kubectl get pods \
    -n "$NAMESPACE"


echo

kubectl get svc \
    -n "$NAMESPACE"
