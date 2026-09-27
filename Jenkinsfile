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

        ROLE_ARN = "arn:aws:iam::761018849945:role/enterprise-platform-terraform-role"

        TF_IN_AUTOMATION = "true"

        TF_ENV = "dev"

        ARGOCD_HOSTNAME = "argocd.dev.dreammyles.online"

        ARGOCD_CHART_VERSION = "10.2.0"

        TMPDIR = '/var/jenkins_home/terraform-tmp'

        K8S_API_CIDRS = '''[
          "174.2.8.121/32",
          "70.64.74.185/32",
          "54.234.38.90/32"
        ]'''
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
                        text: "allowed_k8s_api_cidrs = ${env.K8S_API_CIDRS}\n"
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
                        echo "=== Terraform environment ==="
                        terraform version

                        echo "=== Disk ==="
                        df -h

                        echo "=== Terraform temp directory ==="
                        export TMPDIR="$HOME/terraform-tmp"
                        mkdir -p "$TMPDIR"
                        chmod 700 "$TMPDIR"

                        echo "TMPDIR=$TMPDIR"
                        ls -ld "$TMPDIR"

                        echo "=== Terraform cache ==="
                        ls -la "$HOME/.terraform.d" || true

                        echo "=== Terraform Init ==="
                        terraform init -input=false
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

        stage('Recover Existing Secrets') {

            when {

                expression {
                    return params.APPLY_CHANGES
                }

            }

            steps {

                dir("environments/${TF_ENV}") {

                    timeout(time: 5, unit: 'MINUTES') {

                        sh '''

                        set -e

                        echo "========================================"
                        echo "Recovering Existing Secrets"
                        echo "========================================"

                        recover_secret() {

                            TF_ADDRESS="$1"
                            SECRET_NAME="$2"

                            echo ""
                            echo "----------------------------------------"
                            echo "Checking Secret"
                            echo "Terraform Address : $TF_ADDRESS"
                            echo "AWS Secret        : $SECRET_NAME"
                            echo "----------------------------------------"

                            #
                            # Already managed by Terraform?
                            #
                            if terraform state show "$TF_ADDRESS" >/dev/null 2>&1; then
                                echo "✓ Already managed by Terraform."
                                return
                            fi

                            #
                            # Does it exist in AWS?
                            #
                            if aws secretsmanager describe-secret \
                                --secret-id "$SECRET_NAME" >/dev/null 2>&1; then

                                echo "✓ Secret exists in AWS."

                                #
                                # Is it scheduled for deletion?
                                #
                                DELETED=$(aws secretsmanager describe-secret \
                                    --secret-id "$SECRET_NAME" \
                                    --query DeletedDate \
                                    --output text)

                                if [ "$DELETED" != "None" ] && [ "$DELETED" != "null" ]; then

                                    echo "Secret is scheduled for deletion."
                                    echo "Restoring..."

                                    aws secretsmanager restore-secret \
                                        --secret-id "$SECRET_NAME"

                                    echo "✓ Secret restored."

                                fi

                                echo "Importing into Terraform state..."

                                if SECRET_ARN=$(aws secretsmanager describe-secret \
                                     --secret-id "$SECRET_NAME" \
                                     --query ARN \
                                     --output text)

                                    echo "Secret ARN: $SECRET_ARN"

                                    terraform import "$TF_ADDRESS" "$SECRET_ARN"
                                then

                                    echo "✓ Import successful."

                                else

                                    echo ""
                                    echo "========================================"
                                    echo "ERROR: Failed to import $SECRET_NAME"
                                    echo "========================================"
                                    exit 1

                                fi

                            else

                                echo "Secret does not exist in AWS."
                                echo "Terraform will create it during apply."

                            fi

                        }

                        #
                        # Recover all managed secrets
                        #

                        recover_secret \
                        'module.secrets_manager.aws_secretsmanager_secret.this["auth-service"]' \
                        'enterprise-platform/dev/auth-service'

                        recover_secret \
                        'module.secrets_manager.aws_secretsmanager_secret.this["grafana/admin"]' \
                        'enterprise-platform/dev/grafana/admin'

                        recover_secret \
                        'module.secrets_manager.aws_secretsmanager_secret.this["alertmanager"]' \
                        'enterprise-platform/dev/alertmanager'

                        echo ""
                        echo "========================================"
                        echo "Secret recovery complete."
                        echo "========================================"

                        '''

                    }

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

        stage('Read Terraform Outputs') {

            when {

                expression {

                    return params.APPLY_CHANGES

                }

            }

            steps {

                dir("environments/${TF_ENV}") {

                    script {

                        echo "Reading Terraform Outputs..."

                        env.CLUSTER_NAME = sh(
                            script: "terraform output -raw cluster_name",
                            returnStdout: true
                        ).trim()

                        env.VPC_ID = sh(
                            script: "terraform output -raw vpc_id",
                            returnStdout: true
                        ).trim()

                        env.APPLICATION_SECURITY_GROUPS = sh(
                            script: "terraform output -json application_security_groups",
                            returnStdout: true
                        ).trim()

                        env.EXTERNAL_DNS_ROLE = sh(
                            script: "terraform output -raw external_dns_role_arn",
                            returnStdout: true
                        ).trim()

                        env.ALB_ROLE = sh(
                            script: "terraform output -raw aws_load_balancer_controller_role_arn",
                            returnStdout: true
                        ).trim()

                        env.CERTIFICATE_ARN = sh(
                            script: "terraform output -raw certificate_arn",
                            returnStdout: true
                        ).trim()

                        env.HOSTED_ZONE_ID = sh(
                            script: "terraform output -raw hosted_zone_id",
                            returnStdout: true
                        ).trim()

                        env.DATABASE_WORKLOAD_IDENTITIES = sh(
                            script: "terraform output -json database_workload_identities 2>/dev/null || echo '{}'",
                            returnStdout: true
                        ).trim()

                        env.DATABASE_WORKLOAD_IAM_ROLE_ARNS = sh(
                            script: "terraform output -json database_workload_iam_role_arns 2>/dev/null || echo '{}'",
                            returnStdout: true
                        ).trim()

                        env.DATABASE_WORKLOAD_NAMESPACES = sh(
                            script: "terraform output -json database_workload_namespaces 2>/dev/null || echo '{}'",
                            returnStdout: true
                        ).trim()

                        env.DATABASE_CATALOG = sh(
                            script: "terraform output -json database_catalog 2>/dev/null || echo '{}'",
                            returnStdout: true
                        ).trim()

                        env.GITOPS_SERVICE_CONTRACT = sh(
                            script: "terraform output -json gitops_service_contract",
                            returnStdout: true
                        ).trim()

                    }

                }

                echo "========================================"
                echo "Terraform Outputs"
                echo "========================================"
                echo "Cluster Name     : ${env.CLUSTER_NAME}"
                echo "VPC ID           : ${env.VPC_ID}"
                echo "Application Security Groups: ${env.APPLICATION_SECURITY_GROUPS}"
                echo "Hosted Zone ID   : ${env.HOSTED_ZONE_ID}"
                echo "Certificate ARN  : ${env.CERTIFICATE_ARN}"
                echo "ExternalDNS Role : ${env.EXTERNAL_DNS_ROLE}"
                echo "ALB Role         : ${env.ALB_ROLE}"
                echo "Database Workload Identities: ${env.DATABASE_WORKLOAD_IDENTITIES}"
                echo "Database Workload IAM Roles : ${env.DATABASE_WORKLOAD_IAM_ROLE_ARNS}"
                echo "Database Workload Namespaces: ${env.DATABASE_WORKLOAD_NAMESPACES}"
                echo "GitOps Service Contract:"
                echo "${env.GITOPS_SERVICE_CONTRACT}"
            }

        }

        stage('Publish GitOps Service Contract') {

            when {
                expression {
                    return params.APPLY_CHANGES
                }
            }

            steps {

                dir("environments/${TF_ENV}") {

                    sh '''
                        set -euo pipefail

                        CONTRACT_FILE="gitops-service-contract.json"
                        CONTRACT_KEY="platform-contract/${TF_ENV}/gitops-service-contract.json"

                        echo "========================================"
                        echo "Publishing GitOps Service Contract"
                        echo "========================================"

                        terraform output -json gitops_service_contract > "${CONTRACT_FILE}"

                        echo "Validating contract..."

                        jq empty "${CONTRACT_FILE}"

                        jq -e '."auth-service"' "${CONTRACT_FILE}" >/dev/null

                        echo "Contract validation summary:"
                        jq 'to_entries[] | {
                          service: .key,
                          namespace: .value.namespace,
                          runtime: .value.runtime,
                          database_enabled: .value.database.enabled,
                          database_engine: .value.database.engine,
                          migration_enabled: .value.migration.enabled,
                          migration_engine: .value.migration.engine
                        }' "${CONTRACT_FILE}"

                        ARTIFACT_BUCKET=$(terraform output -raw artifact_bucket_name)

                        if [ -z "${ARTIFACT_BUCKET}" ]; then
                            echo "ERROR: artifact bucket could not be resolved."
                            exit 1
                        fi

                        echo "Artifact bucket: ${ARTIFACT_BUCKET}"
                        echo "Contract key: ${CONTRACT_KEY}"

                        aws s3 cp \
                            "${CONTRACT_FILE}" \
                            "s3://${ARTIFACT_BUCKET}/${CONTRACT_KEY}" \
                            --content-type application/json

                        echo "Verifying uploaded contract..."

                        aws s3 cp \
                            "s3://${ARTIFACT_BUCKET}/${CONTRACT_KEY}" \
                            - \
                            | jq empty

                        echo "GitOps service contract published successfully."
                        echo "s3://${ARTIFACT_BUCKET}/${CONTRACT_KEY}"
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

        stage('Update GitOps Configuration') {

            when {

                expression {

                    return params.APPLY_CHANGES

                }

            }

            steps {

                dir("gitops") {

                    sshagent(credentials: ['github-ssh']) {

                        sh '''

                        echo "========================================"
                        echo "Updating GitOps Configuration"
                        echo "========================================"

                        echo "Updating ExternalDNS IAM Role..."

                        yq e -i '
                        .serviceAccount.annotations."eks.amazonaws.com/role-arn" = env(EXTERNAL_DNS_ROLE)
                        ' charts/external-dns/values.yaml

                        echo "Updating AWS Load Balancer Controller VPC..."

                        yq e -i '
                        .vpcId = env(VPC_ID)
                        ' charts/aws-load-balancer-controller/values.yaml

                        echo "Validating AWS Load Balancer Controller VPC..."

                        CURRENT_VPC_ID=$(yq e '.vpcId' charts/aws-load-balancer-controller/values.yaml)

                        if [ "$CURRENT_VPC_ID" != "$VPC_ID" ]; then
                            echo "========================================"
                            echo "ERROR: Incorrect VPC ID in GitOps"
                            echo "========================================"
                            echo "Expected : $VPC_ID"
                            echo "Found    : $CURRENT_VPC_ID"
                            exit 1
                        fi

                        echo "AWS Load Balancer Controller VPC is correct: $CURRENT_VPC_ID"

                        echo "========================================"
                        echo "Updating ACM certificates across GitOps"
                        echo "========================================"

                        echo "Updating ArgoCD ACM Certificate..."

                        yq e -i '
                        .server.ingress.annotations."alb.ingress.kubernetes.io/certificate-arn" = env(CERTIFICATE_ARN)
                        ' charts/argocd/values.yaml

                        echo "Updating ArgoCD Hostname..."

                        yq e -i '
                        .server.ingress.hostname = env(ARGOCD_HOSTNAME)
                        ' charts/argocd/values.yaml

                        yq e -i '
                        .server.ingress.annotations."external-dns.alpha.kubernetes.io/hostname" = env(ARGOCD_HOSTNAME)
                        ' charts/argocd/values.yaml

                        grep -rl "alb.ingress.kubernetes.io/certificate-arn" charts | while read file
                        do
                            # ArgoCD is already updated above
                            if [ "$file" = "charts/argocd/values.yaml" ]; then
                                continue
                            fi

                            echo "Updating certificate ARN in $file"

                            yq e -i '
                            (
                            .. |
                            select(
                                type == "!!map" and
                                has("alb.ingress.kubernetes.io/certificate-arn")
                            )
                            )."alb.ingress.kubernetes.io/certificate-arn" = env(CERTIFICATE_ARN)
                            ' "$file"

                        done

                        echo ""
                        echo "Validating deployed certificate references..."

                        FILES=$(grep -rl "alb.ingress.kubernetes.io/certificate-arn" charts)

                        for file in $FILES
                        do
                            CURRENT=$(yq e '
                            ..
                            | select(
                                type == "!!map" and
                                has("alb.ingress.kubernetes.io/certificate-arn")
                            )
                            ."alb.ingress.kubernetes.io/certificate-arn"
                            ' "$file")

                            if [ "$CURRENT" != "$CERTIFICATE_ARN" ]; then
                                echo "========================================"
                                echo "ERROR: Incorrect certificate found"
                                echo "========================================"
                                echo "File     : $file"
                                echo "Expected : $CERTIFICATE_ARN"
                                echo "Found    : $CURRENT"
                                exit 1
                            fi
                        done

                        echo "All deployed resources reference the correct ACM certificate."

                        # -------------------------------------------------
                        # Auth-service platform contract
                        # -------------------------------------------------

                        echo "========================================"
                        echo "Applying auth-service platform contract"
                        echo "========================================"

                        export AUTH_SERVICE_CONTRACT=$(echo "$GITOPS_SERVICE_CONTRACT" | \
                            jq -c '.["auth-service"] // empty')

                        if [ -z "$AUTH_SERVICE_CONTRACT" ]; then
                            echo "ERROR: auth-service contract could not be resolved."
                            echo "GitOps service contract:"
                            echo "$GITOPS_SERVICE_CONTRACT"
                            exit 1
                        fi

                        export AUTH_DB_ENABLED=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.database.enabled // false')

                        export AUTH_DB_HOST=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.database.host // empty')

                        export AUTH_DB_PORT=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.database.port // empty')

                        export AUTH_DB_NAME=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.database.name // empty')

                        export AUTH_DB_CREDENTIAL_REFERENCE=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.database.credential_reference // empty')

                        export AUTH_SERVICE_DB_ROLE_ARN=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.workload_identity.role_arn // empty')

                        export AUTH_SERVICE_SG=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.security_group.id // empty')

                        export AUTH_MIGRATION_ENABLED=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.migration.enabled // false')

                        export AUTH_MIGRATION_ENGINE=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.migration.engine // empty')

                        export AUTH_MIGRATION_ROLE_ARN=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.migration.role_arn // empty')

                        export AUTH_MIGRATION_SERVICE_ACCOUNT=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.migration.service_account_name // empty')

                        export AUTH_MIGRATION_ARTIFACT_BUCKET=$(echo "$AUTH_SERVICE_CONTRACT" | \
                            jq -r '.migration.artifact.bucket // empty')

                        echo "Auth-service contract resolved:"
                        echo "  Database enabled      : $AUTH_DB_ENABLED"
                        echo "  Database host         : $AUTH_DB_HOST"
                        echo "  Database port         : $AUTH_DB_PORT"
                        echo "  Database name         : $AUTH_DB_NAME"
                        echo "  Credential reference  : configured"
                        echo "  Database IAM role     : configured"
                        echo "  Security group        : $AUTH_SERVICE_SG"
                        echo "  Migration enabled     : $AUTH_MIGRATION_ENABLED"
                        echo "  Migration engine      : $AUTH_MIGRATION_ENGINE"
                        echo "  Migration role        : configured"
                        echo "  Migration service acct: $AUTH_MIGRATION_SERVICE_ACCOUNT"
                        echo "  Migration bucket      : $AUTH_MIGRATION_ARTIFACT_BUCKET"

                        if [ "$AUTH_DB_ENABLED" = "true" ]; then

                            if [ -z "$AUTH_DB_HOST" ] || \
                               [ -z "$AUTH_DB_PORT" ] || \
                               [ -z "$AUTH_DB_NAME" ] || \
                               [ -z "$AUTH_DB_CREDENTIAL_REFERENCE" ]; then

                                echo "ERROR: auth-service database contract is incomplete."
                                exit 1
                            fi

                            echo "Configuring auth-service database contract..."

                            yq e -i \
                                '.database.enabled = true' \
                                charts/auth-service/values-dev.yaml

                            yq e -i \
                                '.database.host = env(AUTH_DB_HOST)' \
                                charts/auth-service/values-dev.yaml

                            yq e -i \
                                '.database.port = env(AUTH_DB_PORT)' \
                                charts/auth-service/values-dev.yaml

                            yq e -i \
                                '.database.name = env(AUTH_DB_NAME)' \
                                charts/auth-service/values-dev.yaml

                            yq e -i \
                                '.database.credentialReference = env(AUTH_DB_CREDENTIAL_REFERENCE)' \
                                charts/auth-service/values-dev.yaml

                        fi

                        if [ -n "$AUTH_SERVICE_DB_ROLE_ARN" ]; then

                            echo "Configuring auth-service database workload identity..."

                            yq e -i \
                                '.serviceAccount.create = true' \
                                charts/auth-service/values-dev.yaml

                            yq e -i \
                                '.serviceAccount.annotations."eks.amazonaws.com/role-arn" = env(AUTH_SERVICE_DB_ROLE_ARN)' \
                                charts/auth-service/values-dev.yaml

                        fi

                        if [ -n "$AUTH_SERVICE_SG" ]; then

                            echo "Configuring auth-service SecurityGroupPolicy..."

                            yq e -i \
                                '.securityGroupPolicy.enabled = true |
                                 .securityGroupPolicy.groupId = env(AUTH_SERVICE_SG)' \
                                charts/auth-service/values-dev.yaml

                        fi

                        if [ "$AUTH_MIGRATION_ENABLED" = "true" ]; then

                            if [ "$AUTH_MIGRATION_ENGINE" != "flyway" ]; then
                                echo "ERROR: Unsupported auth-service migration engine: $AUTH_MIGRATION_ENGINE"
                                exit 1
                            fi

                            if [ -z "$AUTH_MIGRATION_ROLE_ARN" ] || \
                               [ -z "$AUTH_MIGRATION_SERVICE_ACCOUNT" ] || \
                               [ -z "$AUTH_MIGRATION_ARTIFACT_BUCKET" ]; then

                                echo "ERROR: auth-service migration contract is incomplete."
                                exit 1
                            fi

                            echo "Configuring auth-service migration contract..."

                            yq e -i \
                                '.migration.enabled = true |
                                 .migration.engine = env(AUTH_MIGRATION_ENGINE) |
                                 .migration.artifact.bucket = env(AUTH_MIGRATION_ARTIFACT_BUCKET) |
                                 .migration.serviceAccount.name = env(AUTH_MIGRATION_SERVICE_ACCOUNT) |
                                 .migration.serviceAccount.roleArn = env(AUTH_MIGRATION_ROLE_ARN)' \
                                charts/auth-service/values-dev.yaml

                            if [ -n "$AUTH_SERVICE_SG" ]; then
                                yq e -i \
                                    '.migration.securityGroupPolicy.enabled = true |
                                     .migration.securityGroupPolicy.groupId = env(AUTH_SERVICE_SG)' \
                                    charts/auth-service/values-dev.yaml
                            fi

                        fi

                        echo ""
                        echo "Auth-service platform configuration:"
                        yq e '.serviceAccount' charts/auth-service/values-dev.yaml
                        yq e '.database' charts/auth-service/values-dev.yaml
                        yq e '.securityGroupPolicy' charts/auth-service/values-dev.yaml
                        yq e '.migration' charts/auth-service/values-dev.yaml

                        # -------------------------------------------------
                        # Platform environment configuration
                        # -------------------------------------------------

                        echo "========================================"
                        echo "Publishing Platform Environment Configuration"
                        echo "========================================"

                        PLATFORM_ENV_FILE="platform/environments/${TF_ENV}.yaml"

                        mkdir -p "$(dirname "${PLATFORM_ENV_FILE}")"

                        ARTIFACT_BUCKET=$(terraform output -raw artifact_bucket_name)

                        if [ -z "${ARTIFACT_BUCKET}" ]; then
                            echo "ERROR: Artifact bucket could not be resolved."
                            exit 1
                        fi

                        cat > "${PLATFORM_ENV_FILE}" <<EOF
environment: ${TF_ENV}

artifactStore:
  bucket: ${ARTIFACT_BUCKET}
EOF

                        echo "Platform environment configuration:"
                        cat "${PLATFORM_ENV_FILE}"

                        echo ""
                        echo "Git Changes"

                        git diff

                        git add .

                        if git diff --cached --quiet
                        then

                            echo "No GitOps configuration changes detected."

                        else

                            git config user.email "jenkins@enterprise-platform.local"
                            git config user.name "Jenkins"

                            git commit -m "Update GitOps configuration from Terraform outputs"

                            git push origin main

                        fi

                        '''

                    }

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

                echo "Installing ArgoCD using GitOps values..."

                if helm status argocd -n argocd >/dev/null 2>&1; then
                    echo "ArgoCD already installed."

                    helm upgrade argocd \
                      argo/argo-cd \
                      --namespace argocd \
                      --version ${ARGOCD_CHART_VERSION} \
                      --values gitops/charts/argocd/values.yaml \
                      --wait \
                      --timeout 15m

                else
                    echo "Installing ArgoCD..."

                    helm install argocd \
                      argo/argo-cd \
                      --namespace argocd \
                      --create-namespace \
                      --version ${ARGOCD_CHART_VERSION} \
                      --values gitops/charts/argocd/values.yaml \
                      --wait \
                      --timeout 15m
                fi  

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
          --secret-id argocd/gitops/private-key1 \
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
                echo "Waiting for ArgoCD Applications to become healthy..."

                for i in $(seq 1 30); do

                    kubectl get applications -n argocd \
                    -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status

                    NOT_READY=$(kubectl get applications -n argocd \
                    -o jsonpath='{range .items[*]}{.status.health.status}{" "}{.status.sync.status}{"\n"}{end}' \
                    | grep -v "Healthy Synced" || true)

                    if [ -z "$NOT_READY" ]; then
                        echo "All applications are Healthy and Synced."
                        break
                    fi

                    echo "Applications still reconciling..."
                    sleep 20

                done

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