pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO_NAME = '203918866361.dkr.ecr.ap-south-1.amazonaws.com/myapp'
        IMAGE_TAG = "${BUILD_NUMBER}"
        GITHUB_CREDS = 'github-https-creds'       // Jenkins credential ID for GitHub PAT
        AWS_CREDS = 'aws-ecr-creds'               // Jenkins credential ID for AWS IAM access key
    }

    stages {

        stage('Checkout Code') {
            steps {
                git credentialsId: "${GITHUB_CREDS}", url: 'https://github.com/malir001/terraform-ecs.git', branch: 'master'
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDS}"
                ]]) {
                    sh '''
                        cd terraform
                        terraform init
                        terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDS}"
                ]]) {
                    sh '''
                        cd terraform
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} .
                    """
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDS}"
                ]]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
                    '''
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    def accountId = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                    def ecrRepoUri = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

                    sh """
                        docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ecrRepoUri}:${IMAGE_TAG}
                        docker push ${ecrRepoUri}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDS}"
                ]]) {
                    sh '''
                        aws ecs update-service \
                          --cluster your-ecs-cluster-name \
                          --service your-ecs-service-name \
                          --force-new-deployment \
                          --region $AWS_REGION
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo '❌ Pipeline failed.'
        }
        success {
            echo '✅ Deployment complete.'
        }
    }
}
