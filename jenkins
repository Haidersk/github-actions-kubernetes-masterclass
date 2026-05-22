pipeline {

        stage('Run Ansible') {
            steps {
                sh 'ansible-playbook ansible/playbooks/setup.yml'
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
                    credentialsId: 'dockerhub',
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
