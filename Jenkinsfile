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
    }

    stages {

        // ==========================================
        // 1. CHECKOUT
        // ==========================================

        stage("Checkout") {

            steps {

                echo "Downloading source code from GitHub..."

                checkout scm
            }
        }

        // ==========================================
        // 2. PYTHON SYNTAX CHECK
        // ==========================================

        stage("Python Syntax Check") {

            steps {

                echo "Checking Python syntax..."

                sh """
                    python3 -m py_compile app.py
                """
            }
        }

        // ==========================================
        // 3. INSTALL DEPENDENCIES
        // ==========================================

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

        // ==========================================
        // 4. RUN TESTS
        // ==========================================

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

        // ==========================================
        // 5. BUILD DOCKER IMAGE
        // ==========================================

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

        // ==========================================
        // 6. PUSH DOCKER IMAGE
        // ==========================================

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

        // ==========================================
        // 7. DEPLOY TO KUBERNETES
        // ==========================================

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

        // ==========================================
        // 8. HEALTH CHECK
        // ==========================================

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
    }

    // ==============================================
    // POST ACTIONS
    // ==============================================

    post {

        // ------------------------------------------
        // SUCCESS
        // ------------------------------------------

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
                http://localhost:5050

                Health:
                http://localhost:5050/health
                ==========================================
            """
        }

        // ------------------------------------------
        // FAILURE
        // ------------------------------------------

        failure {

            echo """
                ==========================================
                Karan DevOps Dashboard
                Jenkins pipeline failed.

                Check Jenkins console output.
                ==========================================
            """
        }

        // ------------------------------------------
        // ALWAYS
        // ------------------------------------------

        always {

            sh '''
                echo "=========================================="
                echo "Kubernetes Pods:"
                echo "=========================================="

                kubectl get pods \
                    -n "$K8S_NAMESPACE" \
                    || true

                echo

                echo "=========================================="
                echo "Kubernetes Services:"
                echo "=========================================="

                kubectl get svc \
                    -n "$K8S_NAMESPACE" \
                    || true

                echo

                echo "=========================================="
                echo "Port Forward Process:"
                echo "=========================================="

                ps aux | grep \
                    '[k]ubectl port-forward' \
                    || true
            '''
        }
    }
}
