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
                sh 'terraform/ansible/playbook.yml'
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
