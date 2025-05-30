pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '203918866361.dkr.ecr.ap-south-1.amazonaws.com/myapp'
        IMAGE_TAG = 'latest'
        GIT_CREDENTIALS_ID = 'github-creds'
        AWS_CREDENTIALS_ID = 'aws-ecr-creds'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/malir001/terraform-ecs.git',
                        credentialsId: "${GIT_CREDENTIALS_ID}"
                    ]]
                ])
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${ECR_REPO}:${IMAGE_TAG}")
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                                  credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    sh """
                        aws ecr get-login-password --region $AWS_REGION | \
                        docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
                    """
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
                        terraform plan
                        terraform apply -auto-approve
                    """
                }
            }
        }
    }

    post {
        failure {
            echo 'Build failed!'
        }
        success {
            echo 'Build succeeded!'
        }
    }
}
