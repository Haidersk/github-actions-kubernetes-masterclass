pipeline {
    agent any

    environment {
        DOCKER_BACKEND  = "haider3897/skillpulse-backend"
        DOCKER_FRONTEND = "haider3897/skillpulse-frontend"
        TAG             = "${BUILD_NUMBER}"
        SONAR_HOST      = "http://23.20.132.235:9000"
        ANSIBLE_IP      = "18.209.224.167"
    }

    stages {

        // ── 1. CLONE ─────────────────────────────────────────────────
        stage('Clone Repository') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Haidersk/github-actions-kubernetes-masterclass.git'
            }
        }

        // ── 2. DEBUG ─────────────────────────────────────────────────
        stage('Debug Repo Structure') {
            steps {
                sh '''
                    pwd
                    ls -la
                    ls -la Terraform/environment/prod || echo "ERROR: PATH NOT FOUND"
                '''
            }
        }

        // ── 3. TERRAFORM ─────────────────────────────────────────────
        stage('Terraform Init') {
            steps {
                sh '''
                    cd Terraform/environment/prod
                    terraform init
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                    cd Terraform/environment/prod
                    terraform apply -auto-approve
                '''
            }
        }

        // ── 4. ANSIBLE ───────────────────────────────────────────────
        stage('Run Ansible') {
            steps {
                sshagent(credentials: ['ansible-ssh-key']) {
                    sh '''
                        echo "EC2 Public IP: $ANSIBLE_IP"

                        echo "[jenkins]" > /tmp/inventory.ini
                        echo "$ANSIBLE_IP ansible_user=ubuntu" >> /tmp/inventory.ini

                        echo "=== Generated Inventory ==="
                        cat /tmp/inventory.ini

                        ssh-keyscan -H $ANSIBLE_IP >> ~/.ssh/known_hosts 2>/dev/null

                        ansible-playbook Terraform/Ansible/playbook.yml \
                            --inventory /tmp/inventory.ini \
                            -u ubuntu \
                            -v
                    '''
                }
            }
        }

        // ── 5. SONARQUBE ─────────────────────────────────────────────
        stage('SonarQube Scan') {
            steps {
                withCredentials([string(
                    credentialsId: 'SONAR_TOKEN',
                    variable: 'SONAR_TOKEN'
                )]) {
                    sh '''
                        sonar-scanner \
                            -Dsonar.projectKey=skillpulse \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=$SONAR_HOST \
                            -Dsonar.login=$SONAR_TOKEN
                    '''
                }
            }
        }

        // ── 6. TRIVY FILE SCAN ───────────────────────────────────────
        stage('Trivy File Scan') {
            steps {
                sh '''
                    trivy fs . \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format table
                '''
            }
        }

        // ── 7. BUILD DOCKER IMAGES ───────────────────────────────────
        stage('Build Docker Images') {
            steps {
                sh 'make build TAG=$TAG'
            }
        }

        // ── 8. TRIVY IMAGE SCAN ──────────────────────────────────────
        stage('Trivy Image Scan') {
            steps {
                sh '''
                    trivy image --severity HIGH,CRITICAL --exit-code 0 $DOCKER_BACKEND:$TAG
                    trivy image --severity HIGH,CRITICAL --exit-code 0 $DOCKER_FRONTEND:$TAG
                '''
            }
        }

        // ── 9. DOCKER LOGIN & PUSH ───────────────────────────────────
        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                }
            }
        }

        stage('Push Images') {
            steps {
                sh '''
                    docker push $DOCKER_BACKEND:$TAG
                    docker push $DOCKER_FRONTEND:$TAG
                '''
            }
        }

        // ── 10. ENSURE KIND CLUSTER ──────────────────────────────────
        stage('Ensure Kind Cluster') {
            steps {
                sh '''
                    # Create cluster if not exists
                    if ! kind get clusters | grep -q skillpulse; then
                        echo "Creating Kind cluster..."
                        kind create cluster --name skillpulse
                    else
                        echo "Kind cluster already exists"
                    fi

                    # Always refresh kubeconfig for jenkins user
                    mkdir -p /var/lib/jenkins/.kube
                    kind get kubeconfig --name skillpulse > /var/lib/jenkins/.kube/config
                    chmod 600 /var/lib/jenkins/.kube/config

                    # Set correct context
                    kubectl config use-context kind-skillpulse

                    # Verify cluster is reachable
                    kubectl cluster-info
                    kubectl get nodes
                '''
            }
        }

        // ── 11. DEPLOY TO KUBERNETES ─────────────────────────────────
        stage('Deploy Kubernetes') {
            steps {
                sh '''
                    # Load images into kind cluster
                    kind load docker-image $DOCKER_BACKEND:$TAG  --name skillpulse
                    kind load docker-image $DOCKER_FRONTEND:$TAG --name skillpulse

                    # Apply manifests
                    make apply TAG=$TAG
                '''
            }
        }

        // ── 12. MONITORING SETUP ─────────────────────────────────────
        stage('Monitoring Setup') {
            steps {
                sh '''
                    # Create monitoring namespace
                    kubectl get namespace monitoring 2>/dev/null || \
                        kubectl create namespace monitoring

                    # Add Helm repos
                    helm repo add prometheus-community \
                        https://prometheus-community.github.io/helm-charts 2>/dev/null || true
                    helm repo add grafana \
                        https://grafana.github.io/helm-charts 2>/dev/null || true
                    helm repo update

                    # Install Prometheus
                    helm upgrade --install prometheus \
                        prometheus-community/prometheus \
                        -n monitoring \
                        --wait --timeout 3m

                    # Install Grafana
                    helm upgrade --install grafana \
                        grafana/grafana \
                        -n monitoring \
                        --wait --timeout 3m

                    echo "=== Monitoring Stack ==="
                    kubectl get pods -n monitoring
                '''
            }
        }

        // ── 13. VERIFY ───────────────────────────────────────────────
        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "=== Application Pods ==="
                    make status

                    echo "=== Monitoring Pods ==="
                    kubectl get pods -n monitoring

                    echo "=== All Services ==="
                    kubectl get svc -n skillpulse
                    kubectl get svc -n monitoring
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline SUCCESS - Build #${BUILD_NUMBER} deployed successfully"
        }
        failure {
            echo "❌ Pipeline FAILED - Build #${BUILD_NUMBER} - check stage logs above"
        }
    }
}
