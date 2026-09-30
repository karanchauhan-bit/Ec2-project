pipeline {

    agent any

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    environment {
        IMAGE_REPO =
            "karan1989/karan-devops-dashboard"

        IMAGE_TAG =
            "${BUILD_NUMBER}"

        K8S_NAMESPACE =
            "karan-dashboard"

        APP_PORT =
            "5050"
    }

    stages {

        stage("Checkout") {
            steps {
                echo "Downloading source code from GitHub..."
                checkout scm
            }
        }

        stage("Python Syntax Check") {
            steps {
                echo "Checking Python syntax..."
                sh """
                    python3 -m py_compile app.py
                """
            }
        }

        stage("Install Dependencies") {
            steps {
                echo "Installing Python dependencies..."
                sh """
                    python3 -m venv .jenkins-venv
                    .jenkins-venv/bin/pip install \
                        -r requirements.txt
                """
            }
        }

        stage("Run Tests") {
            steps {
                echo "Running Python unit tests..."
                sh """
                    .jenkins-venv/bin/python \
                    -m unittest \
                    discover \
                    -s tests \
                    -v
                """
            }
        }

        stage("Build Docker Image") {
            steps {
                echo "Building Docker image..."
                sh """
                    docker build \
                        -t ${IMAGE_REPO}:${IMAGE_TAG} \
                        -t ${IMAGE_REPO}:latest \
                        .
                """
            }
        }

        stage("Push Docker Image") {
            steps {
                echo "Pushing Docker image to Docker Hub..."

                withCredentials(
                    [
                        usernamePassword(
                            credentialsId:
                                "dockerhub-credentials",
                            usernameVariable:
                                "DOCKERHUB_USERNAME",
                            passwordVariable:
                                "DOCKERHUB_PASSWORD"
                        )
                    ]
                ) {
                    sh '''
                        set -e

                        echo "$DOCKERHUB_PASSWORD" | \
                            docker login \
                            --username "$DOCKERHUB_USERNAME" \
                            --password-stdin

                        docker push \
                            "$IMAGE_REPO:$IMAGE_TAG"

                        docker push \
                            "$IMAGE_REPO:latest"

                        docker logout
                    '''
                }
            }
        }

        stage("Deploy to Kubernetes") {
            steps {
                echo "Deploying application to Kubernetes..."

                sh '''
                    set -e

                    IMAGE_REPO="$IMAGE_REPO" \
                    IMAGE_TAG="$IMAGE_TAG" \
                    K8S_NAMESPACE="$K8S_NAMESPACE" \
                    bash scripts/deploy.sh
                '''
            }
        }

        stage("Health Check") {
            steps {
                echo "Checking Kubernetes application health..."

                sh '''
                    set -e

                    K8S_NAMESPACE="$K8S_NAMESPACE" \
                    bash scripts/health_check.sh
                '''
            }
        }

        stage("Start Port Forward") {
            steps {
                echo "Starting Kubernetes port-forward..."

                sh '''
                    set -e

                    # Stop old port-forward if running
                    pkill -f \
                        'kubectl port-forward.*karan-devops-dashboard-service' \
                        || true

                    # Start new port-forward
                    nohup kubectl port-forward \
                        svc/karan-devops-dashboard-service \
                        ${APP_PORT}:5000 \
                        -n "$K8S_NAMESPACE" \
                        > /tmp/karan-devops-port-forward.log 2>&1 &

                    echo "Waiting for port-forward..."

                    for i in {1..10}
                    do
                        if curl -sf \
                            http://localhost:${APP_PORT}/health \
                            > /dev/null
                        then
                            echo "Port-forward is ready."
                            break
                        fi

                        sleep 2
                    done

                    echo
                    echo "Application URL:"
                    echo "http://localhost:${APP_PORT}"
                '''
            }
        }
    }

    post {

        success {
            echo """
                ==========================================
                Karan DevOps Dashboard
                Jenkins deployment successful.

                Image:
                ${IMAGE_REPO}:${IMAGE_TAG}

                Namespace:
                ${K8S_NAMESPACE}

                Application:
                http://localhost:${APP_PORT}

                Health:
                http://localhost:${APP_PORT}/health
                ==========================================
            """
        }

        failure {
            echo """
                ==========================================
                Karan DevOps Dashboard
                Jenkins pipeline failed.

                Check Jenkins console output.
                ==========================================
            """
        }

        always {
            sh '''
                echo "Kubernetes Pods:"

                kubectl get pods \
                    -n "$K8S_NAMESPACE" \
                    || true

                echo
                echo "Kubernetes Services:"

                kubectl get svc \
                    -n "$K8S_NAMESPACE" \
                    || true

                echo
                echo "Port-forward process:"

                ps aux | grep \
                    '[k]ubectl port-forward' \
                    || true
            '''
        }
    }
}
```

