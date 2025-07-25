pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub')
        AWS_CREDS = credentials('aws-creds')
    }

    stages {
        stage('Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/asadali2004/flask-app.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                bat 'docker build -t asadali2004/flask-app:latest .'
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    bat """
                        echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin
                        docker push asadali2004/flask-app:latest
                    """
                }
            }
        }

        stage('Terraform Deploy') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    bat """
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                    """
                }
            }
        }

        stage('Terraform Destroy') {
            steps {
                input message: 'Do you want to destroy the infrastructure?', ok: 'Yes, Destroy'
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    bat '''
                        cd terraform
                        terraform destroy -auto-approve
                    '''
                }
            }
        }

    }

}
