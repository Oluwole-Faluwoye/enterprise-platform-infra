pipeline {

    agent any

    parameters {

        booleanParam(
            name: 'APPLY_CHANGES',
            defaultValue: false,
            description: 'Apply Terraform changes after approval'
        )

        string(
            name: 'KEY_NAME',
            defaultValue: 'us-east-1-key',
            description: 'AWS EC2 Key Pair Name'
        )

        string(
            name: 'HOME_IP',
            defaultValue: '174.2.8.121/32',
            description: 'Allowed SSH Source IP'
        )
    }

    environment {

        AWS_REGION = "us-east-1"

        ROLE_ARN = "arn:aws:iam::761018849945:role/terraform-deployer-role"

        TF_IN_AUTOMATION = "true"

        TF_ENV = "dev"
    }

    options {

        timestamps()

        disableConcurrentBuilds()

        buildDiscarder(
            logRotator(
                numToKeepStr: '20'
            )
        )

        ansiColor('xterm')
    }

    stages {

        stage('Checkout') {

            steps {

                echo "Checking out infrastructure code..."

                checkout scm
            }
        }

        stage('Assume Terraform Role') {

            steps {

                script {

                    def creds = sh(

                        script: """
                        aws sts assume-role \
                          --role-arn ${ROLE_ARN} \
                          --role-session-name terraform-jenkins
                        """,

                        returnStdout: true

                    ).trim()

                    def json = readJSON text: creds

                    env.AWS_ACCESS_KEY_ID =
                        json.Credentials.AccessKeyId

                    env.AWS_SECRET_ACCESS_KEY =
                        json.Credentials.SecretAccessKey

                    env.AWS_SESSION_TOKEN =
                        json.Credentials.SessionToken
                }

                sh '''

                aws sts get-caller-identity

                '''
            }
        }

        stage('Terraform Format') {

            steps {

                sh '''

                terraform fmt -check -recursive

                '''
            }
        }

        stage('Create Runtime tfvars') {

            steps {

                dir("environments/${TF_ENV}") {

                    writeFile(

                        file: 'terraform.tfvars',

                        text: """
key_name = "${params.KEY_NAME}"

home_ip = "${params.HOME_IP}"
"""
                    )

                    sh '''

                    echo "Generated terraform.tfvars"

                    cat terraform.tfvars

                    '''
                }
            }
        }

        stage('Terraform Init') {

            steps {

                dir("environments/${TF_ENV}") {

                    sh '''

                    terraform init

                    '''
                }
            }
        }

        stage('Terraform Validate') {

            steps {

                dir("environments/${TF_ENV}") {

                    sh '''

                    terraform validate

                    '''
                }
            }
        }

        stage('tfsec Scan') {

            steps {

                dir("environments/${TF_ENV}") {

                    sh '''

                    docker run --rm \
                      -v $(pwd):/src \
                      aquasec/tfsec \
                      /src

                    '''
                }
            }
        }

        stage('Checkov Scan') {

            steps {

                dir("environments/${TF_ENV}") {

                    sh '''

                    docker run --rm \
                      -v $(pwd):/tf \
                      bridgecrew/checkov \
                      -d /tf

                    '''
                }
            }
        }

        stage('Terraform Plan') {

            steps {

                dir("environments/${TF_ENV}") {

                    sh '''

                    terraform plan \
                      -out=tfplan

                    '''
                }
            }
        }

        stage('Archive Plan') {

            steps {

                archiveArtifacts(
                    artifacts: "environments/${TF_ENV}/tfplan"
                )
            }
        }

        stage('Manual Approval') {

            when {

                expression {

                    return params.APPLY_CHANGES
                }
            }

            steps {

                input(

                    message: 'Approve Terraform Apply?',

                    ok: 'Apply'
                )
            }
        }

        stage('Terraform Apply') {

            when {

                expression {

                    return params.APPLY_CHANGES
                }
            }

            steps {

                dir("environments/${TF_ENV}") {

                    sh '''

                    terraform apply \
                      -auto-approve \
                      tfplan

                    '''
                }
            }
        }
    
        
        stage('Validate EKS Cluster') {

            when {

                expression {

                    return params.APPLY_CHANGES
                }
            }

            steps {

                dir("environments/${TF_ENV}") {

                    sh '''

                    CLUSTER_NAME=$(terraform output -raw cluster_name)

                    echo "Cluster Name: ${CLUSTER_NAME}"

                    aws eks describe-cluster \
                      --name ${CLUSTER_NAME} \
                      --region ${AWS_REGION}

                    '''
                }
            }
        }

        stage('Configure kubectl') {

            when {

                expression {

                    return params.APPLY_CHANGES
                }
            }

            steps {

                dir("environments/${TF_ENV}") {

                    sh '''

                    CLUSTER_NAME=$(terraform output -raw cluster_name)

                    aws eks update-kubeconfig \
                      --name ${CLUSTER_NAME} \
                      --region ${AWS_REGION}

                    kubectl get nodes -o wide 

                    '''
                }
            }
        }

        stage('Install ArgoCD') {

            when {

                expression {

                    return params.APPLY_CHANGES
                }
            }

            steps {

                sh '''

                helm repo add argo https://argoproj.github.io/argo-helm

                helm repo update

                helm upgrade --install argocd \
                  argo/argo-cd \
                  --namespace argocd \
                  --create-namespace \
                  --wait \
                  --timeout 10m

                '''
            }
        }

        stage('Wait For ArgoCD') {

            when {

                expression {

                    return params.APPLY_CHANGES
                }
            }

            steps {

                sh '''

                echo "Checking ArgoCD pods..." 
                
                kubectl get pods -n argocd 
                
                echo "Waiting for ArgoCD Server..."


                kubectl wait \
                  --for=condition=available \
                  deployment/argocd-server \
                  -n argocd \
                  --timeout=600s
                
                echo "ArgoCD is ready."

                kubectl get pods -n argocd
            

                '''
            }
        }

        stage('Checkout GitOps Repo') {

            when {

                expression {

                    return params.APPLY_CHANGES
                }
            }

            steps {

                dir('gitops') {

                    git(
                        branch: 'main',
                        credentialsId: 'github-ssh',
                        url: 'git@github.com:Oluwole-Faluwoye/enterprise-platform-gitops.git'
                    )
                }
            }
        }

        stage('Bootstrap GitOps') {

            when {

                expression {

                    return params.APPLY_CHANGES
                }
            }

            steps {

                sh '''

                echo "Applying Root App..."

                kubectl apply \
                  -f gitops/root-app.yaml

                kubectl get application root-app \
                  -n argocd || true  

                '''
            }
        }

        stage('Verify GitOps') {

            when {

                expression {

                    return params.APPLY_CHANGES
                }
            }

            steps {

                sh '''

                echo "ArgoCD Applications"

                kubectl get applications -n argocd || true

                kubectl describe application root-app -n argocd || true

                echo "ArgoCD Pods"

                kubectl get pods -n argocd

                echo "ArgoCD Services"

                kubectl get svc -n argocd

                '''
            }
        }
    }


        post {

            success {

                echo "Infrastructure deployment successful."
            }

            failure {

                echo "Infrastructure deployment failed."
            }

            always {

                cleanWs()
            }
        }
    }