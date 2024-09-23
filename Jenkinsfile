pipeline {
    agent any

    stages {
        stage('GitHub Checkout') {
            steps {
                echo 'Starting GitHub checkout...'
                script {
                    try {
                        git 'https://github.com/gitkailash/aws-wordpress-terraform-setup.git'
                        echo 'GitHub checkout completed.'
                    } catch (Exception e) {
                        error 'GitHub checkout failed. Please check the repository URL or access permissions.'
                    }
                }
            }
        }

        stage('Set Up Terraform Cloud') {
            steps {
                script {
                    def workspace = env.WORKSPACE
                    echo "Using Terraform Cloud workspace: ${workspace}"

                    withCredentials([string(credentialsId: 'TERRAFORM_CLOUD_TOKEN', variable: 'TERRAFORM_TOKEN')]) {
                        sh 'export TF_TOKEN=$TERRAFORM_TOKEN'
                        echo 'Terraform Cloud token set.'
                    }

                    echo 'Initializing Terraform...'
                    try {
                        sh "terraform init"
                        echo 'Terraform initialization completed.'
                    } catch (Exception e) {
                        error 'Terraform initialization failed. Please check the logs for details.'
                    }
                }
            }
        }

        stage('Deploy to Environments') {
            steps {
                script {
                    def environments = ['dev', 'qa', 'prod']

                    for (env in environments) {
                        echo "Switching to Terraform workspace: ${env}"
                        try {
                            sh "terraform workspace select ${env} || terraform workspace new ${env}"
                        } catch (Exception e) {
                            error "Failed to switch or create workspace: ${env}. Please check the logs."
                        }

                        echo 'Validating Terraform configuration...'
                        try {
                            sh "terraform validate"
                            echo 'Terraform validation successful.'
                        } catch (Exception e) {
                            error 'Terraform validation failed. Please check the configuration.'
                        }

                        echo 'Creating Terraform execution plan...'
                        try {
                            sh "terraform plan -out=tfplan"
                            echo 'Terraform plan created successfully.'
                        } catch (Exception e) {
                            error 'Terraform plan creation failed. Please check the logs.'
                        }

                        echo "Awaiting approval for deployment to the ${env} environment..."
                        input message: "Approve deployment to ${env} environment?", ok: "Deploy"
                        echo "Deploying to the ${env} environment..."
                        try {
                            sh "terraform apply -auto-approve tfplan"
                            echo "Deployment to the ${env} environment completed successfully."
                        } catch (Exception e) {
                            error "Deployment to ${env} environment failed. Please check the logs."
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Deployment process completed for all environments.'
        }
        success {
            echo 'All environments deployed successfully.'
        }
        failure {
            echo 'Deployment failed. Please check the logs for details.'
        }
    }
}
