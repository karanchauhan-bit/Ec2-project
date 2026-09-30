# Karan DevOps Dashboard

A practical DevOps project using:

- Python
- Flask
- MySQL
- HTML
- CSS
- JavaScript
- Docker
- Docker Compose
- Git
- GitHub
- Jenkins
- Docker Hub
- Kubernetes
- AWS EC2


## Project Flow

GitHub
    |
    v
Jenkins
    |
    +--> Checkout
    |
    +--> Syntax Check
    |
    +--> Unit Tests
    |
    +--> Docker Build
    |
    +--> Docker Push
    |
    +--> Kubernetes Deploy
    |
    +--> Health Check
            |
            v
       Kubernetes
          |     |
          v     v
       Flask   MySQL
       2 Pods   1 Pod


## Local Docker Compose

Start:

docker compose up -d --build


Check:

docker compose ps


Application:

http://localhost:5000


Health:

curl http://localhost:5000/health


Stop:

docker compose down


Remove database volume:

docker compose down -v


## Unit Tests

python3 -m unittest discover -s tests -v


## Kubernetes Namespace

karan-dashboard


## Kubernetes Application

2 Flask replicas.


## Kubernetes Database

1 MySQL replica.


## Application Service

NodePort:

30080


## MySQL Service

ClusterIP:

3306


## Jenkins Pipeline

Checkout
Syntax Check
Unit Tests
Docker Build
Docker Push
Kubernetes Deploy
Health Check


## Docker Image Tags

Jenkins BUILD_NUMBER is used.

Build #1:

karan-devops-dashboard:1


Build #2:

karan-devops-dashboard:2


Build #3:

karan-devops-dashboard:3


latest is also updated.


## Repeated Jenkins Runs

Kubernetes resources are updated using kubectl apply.

The application Deployment uses RollingUpdate.

Repeated pipeline runs do not create duplicate Deployments or Services.


## Local Database

DB_HOST=mysql


## Kubernetes Database

DB_HOST=karan-mysql-service


## Kubernetes Storage

PersistentVolume
    |
    v
PersistentVolumeClaim
    |
    v
MySQL


## Useful Commands

kubectl get all -n karan-dashboard

kubectl get pods -n karan-dashboard

kubectl get pvc -n karan-dashboard

kubectl get svc -n karan-dashboard

kubectl logs deployment/karan-devops-dashboard -n karan-dashboard


## Port Forward

kubectl port-forward \
    service/karan-devops-dashboard-service \
    5000:5000 \
    -n karan-dashboard


Then open:

http://localhost:5000
