pipeline {
    agent any

    environment {
        DOCKER_BACKEND  = "haider3897/skillpulse-backend"
        DOCKER_FRONTEND = "haider3897/skillpulse-frontend"
        TAG             = "${BUILD_NUMBER}"
        SONAR_HOST      = "http://54.165.117.57:9000"
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
                sh '''
                    pwd
                    ls -la
                    ls -la Terraform/environment/prod || echo "ERROR: PATH NOT FOUND"
                '''
            }
        }

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

        stage('Run Ansible') {
            steps {
                sh '''
                    ansible-playbook Terraform/Ansible/playbook.yml \
                        --inventory Terraform/Ansible/inventory.tpl \
                        -v
                '''
            }
        }

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

        stage('Build Docker Images') {
            steps {
                sh 'make build TAG=$TAG'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    trivy image --severity HIGH,CRITICAL --exit-code 0 $DOCKER_BACKEND:$TAG
                    trivy image --severity HIGH,CRITICAL --exit-code 0 $DOCKER_FRONTEND:$TAG
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

        stage('Deploy Kubernetes') {
            steps {
                sh 'make apply TAG=$TAG'
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'make status'
            }
        }
    }

    post {
        success {
            echo "Pipeline SUCCESS - Build #${BUILD_NUMBER}"
        }
        failure {
            echo "Pipeline FAILED - Build #${BUILD_NUMBER}"
        }
    }
}
