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

        // ── 1. CLONE REPOSITORY ─────────────────────────────────
        stage('Clone Repository') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Haidersk/github-actions-kubernetes-masterclass.git'
            }
        }

        // ── 2. TERRAFORM ────────────────────────────────────────
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

        // ── 3. ANSIBLE ──────────────────────────────────────────
        stage('Run Ansible') {
            steps {
                sshagent(credentials: ['ansible-ssh-key']) {

                    sh '''
                        echo "[jenkins]" > /tmp/inventory.ini
                        echo "$ANSIBLE_IP ansible_user=ubuntu" >> /tmp/inventory.ini

                        ssh-keyscan -H $ANSIBLE_IP >> ~/.ssh/known_hosts 2>/dev/null

                        ansible-playbook Terraform/Ansible/playbook.yml \
                            --inventory /tmp/inventory.ini \
                            -u ubuntu \
                            -v
                    '''
                }
            }
        }

        // ── 4. SONARQUBE ────────────────────────────────────────
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

        // ── 5. TRIVY FILE SCAN ──────────────────────────────────
        stage('Trivy File Scan') {
            steps {
                sh '''
                    trivy fs . \
                    --severity HIGH,CRITICAL \
                    --exit-code 0
                '''
            }
        }

        // ── 6. BUILD DOCKER IMAGES ──────────────────────────────
        stage('Build Docker Images') {
            steps {
                sh '''
                    docker build -t $DOCKER_BACKEND:$TAG ./backend

                    docker build -t $DOCKER_FRONTEND:$TAG ./frontend
                '''
            }
        }

        // ── 7. TRIVY IMAGE SCAN ─────────────────────────────────
        stage('Trivy Image Scan') {
            steps {
                sh '''
                    trivy image $DOCKER_BACKEND:$TAG

                    trivy image $DOCKER_FRONTEND:$TAG
                '''
            }
        }

        // ── 8. DOCKER LOGIN ─────────────────────────────────────
        stage('Docker Login') {
            steps {

                withCredentials([usernamePassword(
                    credentialsId: 'docker',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh '''
                        echo $DOCKER_PASS | docker login \
                        -u $DOCKER_USER --password-stdin
                    '''
                }
            }
        }

        // ── 9. PUSH DOCKER IMAGES ───────────────────────────────
        stage('Push Images') {
            steps {
                sh '''
                    docker push $DOCKER_BACKEND:$TAG

                    docker push $DOCKER_FRONTEND:$TAG
                '''
            }
        }

        // ── 10. UPDATE K8S MANIFESTS ────────────────────────────
        stage('Update Kubernetes Manifests') {
            steps {

                sh '''
                    sed -i "s|image: .*skillpulse-backend.*|image: $DOCKER_BACKEND:$TAG|g" k8s/20-backend.yaml

                    sed -i "s|image: .*skillpulse-frontend.*|image: $DOCKER_FRONTEND:$TAG|g" k8s/30-frontend.yaml

                    echo "=== Updated Backend Manifest ==="
                    grep image k8s/20-backend.yaml

                    echo "=== Updated Frontend Manifest ==="
                    grep image k8s/30-frontend.yaml
                '''
            }
        }

        // ── 11. PUSH UPDATED MANIFESTS TO GITHUB ───────────────
        stage('Push Manifest Changes') {
            steps {

                withCredentials([string(
                    credentialsId: 'github-token',
                    variable: 'GITHUB_TOKEN'
                )]) {

                    sh '''
                        git config user.email "jenkins@cloudforge.com"

                        git config user.name "jenkins"

                        git add k8s/

                        git commit -m "Updated image tags to build $TAG" || echo "No changes to commit"

                        git push https://$GITHUB_TOKEN@github.com/Haidersk/github-actions-kubernetes-masterclass.git HEAD:main
                    '''
                }
            }
        }

        // ── 12. VERIFY ARGOCD ───────────────────────────────────
        stage('Verify ArgoCD Sync') {
            steps {

                sh '''
                    kubectl get applications -n argocd

                    kubectl get pods -n skillpulse

                    kubectl get svc -n skillpulse
                '''
            }
        }
    }

    post {

        success {
            echo "✅ GitOps Pipeline SUCCESS - Build #${BUILD_NUMBER}"
        }

        failure {
            echo "❌ GitOps Pipeline FAILED - Build #${BUILD_NUMBER}"
        }
    }
}
