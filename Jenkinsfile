pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = 'my-ecr-repo'
        IMAGE_TAG = 'latest'
        AWS_CREDENTIALS_ID = 'aws-ecr-creds' // This must match the ID set in Jenkins > Credentials
    }

    stages {
        stage('Checkout') {
            steps {
                git credentialsId: "${AWS_CREDENTIALS_ID}", url: 'https://github.com/malir001/terraform-ecs.git', branch: 'main'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    script {
                        def accountId = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                        def repoUri = "${accountId}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${repoUri}
                        """
                    }
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    def accountId = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                    def repoUri = "${accountId}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

                    sh """
                        docker tag ${ECR_REPO}:${IMAGE_TAG} ${repoUri}:${IMAGE_TAG}
                        docker push ${repoUri}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    sh """
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                    """
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed.'
        }
        success {
            echo 'Pipeline completed successfully.'
        }
    }
}
