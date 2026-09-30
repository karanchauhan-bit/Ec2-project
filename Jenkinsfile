pipeline {

    agent any


    options {

        skipDefaultCheckout(true)

        timestamps()
    }


    environment {

        IMAGE_REPO =
            "YOUR_DOCKERHUB_USERNAME/karan-devops-dashboard"

        IMAGE_TAG =
            "${BUILD_NUMBER}"

        K8S_NAMESPACE =
            "karan-dashboard"
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


        stage("Run Tests") {

            steps {

                echo "Running Python unit tests..."

                sh """
                    python3 \
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
                ==========================================
            """
        }


        failure {

            echo """
                ==========================================
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

                echo "Kubernetes Services:"

                kubectl get svc \
                    -n "$K8S_NAMESPACE" \
                    || true
            '''
        }
    }
}
