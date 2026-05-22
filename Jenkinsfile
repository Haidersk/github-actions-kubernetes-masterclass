<<<<<<< HEAD
pipeline {
    agent any

    environment {
        DOCKER_BACKEND  = "haider3897/skillpulse-backend"
        DOCKER_FRONTEND = "haider3897/skillpulse-frontend"
        TAG             = "${BUILD_NUMBER}"
        SONAR_HOST      = "http://54.165.117.57:9000"
    }

    stages {

        // ── 1. CLONE ─────────────────────────────────────────────────
        stage('Clone Repository') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Haidersk/github-actions-kubernetes-masterclass.git'
            }
        }

        // ── 2. DEBUG (remove once pipeline is stable) ────────────────
        stage('Debug Repo Structure') {
            steps {
                sh '''
                    echo "=== Current directory ==="
                    pwd
                    echo "=== Root files ==="
                    ls -la
                    echo "=== Terraform path check ==="
                    ls -la Terraform/environment/prod || echo "ERROR: Terraform/environment/prod NOT FOUND"
                    echo "=== All directories ==="
                    find . -type d | grep -v ".git"
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
                sh '''
                    ansible-playbook Terraform/ansible/playbook.yml \
                        --inventory Terraform/ansible/inventory.ini \
                        -v
                '''
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
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format table \
                        $DOCKER_BACKEND:$TAG

                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format table \
                        $DOCKER_FRONTEND:$TAG
                '''
            }
        }

        // ── 9. DOCKER LOGIN ──────────────────────────────────────────
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

        // ── 10. PUSH IMAGES ──────────────────────────────────────────
        stage('Push Images') {
            steps {
                sh '''
                    docker push $DOCKER_BACKEND:$TAG
                    docker push $DOCKER_FRONTEND:$TAG
                '''
            }
        }

        // ── 11. DEPLOY KUBERNETES ────────────────────────────────────
        stage('Deploy Kubernetes') {
            steps {
                sh 'make apply TAG=$TAG'
            }
        }

        // ── 12. VERIFY DEPLOYMENT ────────────────────────────────────
        stage('Verify Deployment') {
            steps {
                sh 'make status'
            }
        }
    }

    // ── POST ACTIONS ──────────────────────────────────────────────────
    post {
        success {
            echo "✅ Pipeline SUCCESS — Build #${BUILD_NUMBER} deployed"
        }
        failure {
            echo "❌ Pipeline FAILED — Build #${BUILD_NUMBER} — check stage logs above"
        }
    }
}
=======
pipeline {
    agent any

    environment {
        DOCKER_BACKEND = "haider3897/skillpulse-backend"
        DOCKER_FRONTEND = "haider3897/skillpulse-frontend"
        TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: 'main',
                url: 'https://github.com/Haidersk/github-actions-kubernetes-masterclass.git'
            }
        }

        stage('Debug Repo Structure') {
            steps {
                sh 'pwd'
                sh 'ls -la'
                sh 'find . -type d'
            }
        }
        
        stage('Run Ansible') {
            steps {
                sh 'Terraform/ansible/playbook.yml'
            }
        }

        stage('SonarQube Scan') {
            steps {
                sh 'sonar-scanner'
            }
        }

        stage('Trivy File Scan') {
            steps {
                sh 'trivy fs .'
            }
        }

        stage('Build Docker Images') {
            steps {
                sh 'make build'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                trivy image $DOCKER_BACKEND:$TAG
                trivy image $DOCKER_FRONTEND:$TAG
                '''
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    '''
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

        stage('Deploy Kubernetes') {
            steps {
                sh 'make apply'
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'make status'
            }
        }
    }
}
>>>>>>> 9ae22dbdf11e69046a32c119b728d5a16bdaae7d
