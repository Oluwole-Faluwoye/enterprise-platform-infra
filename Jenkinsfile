pipeline {

    agent any

    parameters {

        booleanParam(
            name: 'APPLY_CHANGES',
            defaultValue: false,
            description: 'Apply Terraform changes after approval'
        )
    }

    environment {

        AWS_REGION = "us-east-1"

        ROLE_ARN = "arn:aws:iam::761018849945:role/terraform-deployer-role"

        TF_IN_AUTOMATION = "true"

        TF_ENV = "dev"

        K8S_API_CIDRS = '''
    [
      "174.2.8.121/32",
      "70.64.74.185/32"
    ]
    '''
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
                    allowed_k8s_api_cidrs = ${env.K8S_API_CIDRS}
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

        stage('Debug GitOps Repo') {

            when {

                expression {

                    return params.APPLY_CHANGES
                }
            }

            steps {

                sh '''

                echo "===== WORKSPACE ====="
                pwd

                echo "===== GITOPS FILES ====="
                find gitops -type f

                echo "===== PLATFORM SERVICES ====="
                ls -R gitops || true

                '''
            }
        }

        stage('Configure ArgoCD Repository') {

    when {

        expression {

            return params.APPLY_CHANGES
        }
    }

    steps {

        sh '''

        echo "Retrieving SSH key from Secrets Manager..."

        set +x

        PRIVATE_KEY=$(aws secretsmanager get-secret-value \
          --secret-id argocd/gitops/private-key-1 \
          --query SecretString \
          --output text)

        echo "Secret retrieved successfully"

cat > repository-secret.yaml <<'EOF'
apiVersion: v1
kind: Secret

metadata:
  name: enterprise-platform-gitops
  namespace: argocd

  labels:
    argocd.argoproj.io/secret-type: repository

type: Opaque

stringData:
  type: git
  url: git@github.com:Oluwole-Faluwoye/enterprise-platform-gitops.git
  sshPrivateKey: |
EOF

        echo "$PRIVATE_KEY" | sed 's/^/    /' >> repository-secret.yaml

        echo "Applying ArgoCD repository secret..."

        kubectl apply -f repository-secret.yaml

        kubectl get secret enterprise-platform-gitops \
          -n argocd

        '''
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

                echo "Bootstrapping ArgoCD..."

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

                echo "========================================"
                echo "ArgoCD Applications"
                echo "========================================"

                kubectl get applications -n argocd || true

                echo ""
                echo "Waiting for Applications to reconcile..."
                sleep 30

                echo ""
                echo "Application Status Summary"

                kubectl get applications -n argocd \
                -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status || true

                echo ""
                echo "Root Application Details"

                kubectl describe application root-app -n argocd || true

                echo ""
                echo "ArgoCD Pods"

                kubectl get pods -n argocd

                echo ""
                echo "ArgoCD Services"

                kubectl get svc -n argocd

                echo ""
                echo "Monitoring Namespace"

                kubectl get pods -n monitoring || true

                echo ""
                echo "Monitoring PVCs"

                kubectl get pvc -n monitoring || true

                echo ""
                echo "Persistent Volumes"

                kubectl get pv || true

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