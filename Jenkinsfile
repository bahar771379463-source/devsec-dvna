pipeline {
    agent any

    environment {
        IMAGE_NAME = "bahar771379463/bahar771379:latest"
        CONTAINER_NAME = "dvna"
        GIT_REPO = "https://github.com/bahar771379463-source/devsec-dvna.git"
        GIT_CREDENTIALS = "github-credentials"
        VAULT_ADDR = "http://192.168.1.2:8200"
        VAULT_CREDENTIALS = "vault-root-tokin"
        TRIVY_CACHE_DIR = "/var/lib/trivy"
        TRIVY_TEMPLATE_DIR = "contrib"
        TRIVY_TEMPLATE_FILE = "html.tpl"
    }

    stages {

        stage('Initialize Trivy Template') {
            steps {
                script {
                    sh "mkdir -p ${TRIVY_TEMPLATE_DIR}"
                    if (!fileExists("${TRIVY_TEMPLATE_DIR}/${TRIVY_TEMPLATE_FILE}")) {
                        echo "📥 Downloading Trivy HTML template..."
                        sh """
                        curl -sSL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl \
                        -o ${TRIVY_TEMPLATE_DIR}/${TRIVY_TEMPLATE_FILE}
                        """
                        echo "✅ Template downloaded successfully."
                    } else {
                        echo "✅ Trivy HTML template already exists. Skipping download."
                    }
                }
            }
        }

        stage('Checkout SCM') {
            steps {
                echo "📥 Cloning repository..."
                git branch: 'main', url: "${GIT_REPO}", credentialsId: "${GIT_CREDENTIALS}"
            }
        }

        stage('Fetch DockerHub Credentials from Vault') {
            steps {
                echo "🔐 Fetching Docker Hub credentials from Vault..."
                withVault([vaultSecrets: [[path: 'secret/docker-credentials',
                    secretValues: [
                        [envVar: 'DOCKERHUB_USER', vaultKey: 'username'],
                        [envVar: 'DOCKERHUB_PASS', vaultKey: 'password']
                    ]
                ]]]) {
                    echo "✅ Credentials loaded from Vault."
                    sh '''
                    echo "🌐 Testing connection to Docker Hub..."
                    curl -I --max-time 10 https://registry-1.docker.io/v2/ || true

                    echo "🔑 Attempting Docker login..."
                    for i in {1..3}; do
                        echo "${DOCKERHUB_PASS}" | docker login -u "${DOCKERHUB_USER}" --password-stdin && break
                        echo "⚠ Login failed... retrying in 10 seconds..."
                        sleep 10
                    done
                    '''
                }
            }
        }

        stage('Check for Code Changes') {
            steps {
                script {
                    echo "🔍 Checking for code or Dockerfile changes..."
                    def changes = sh(script: 'git diff --name-only HEAD~1 HEAD | grep -E "(Dockerfile|package.json|src|server.js)" || true', returnStdout: true).trim()
                    if (changes) {
                        echo "🟠 Code changes detected:\n${changes}"
                        env.CODE_CHANGED = "true"
                    } else {
                        echo "🟢 No code changes detected."
                        env.CODE_CHANGED = "false"
                    }
                }
            }
        }

        stage('Build or Use Existing Image') {
            steps {
                script {
                    echo "⚙ Checking if image exists in Docker Hub..."
                    def imageExists = sh(script: "docker pull ${IMAGE_NAME} || true", returnStatus: true)
                    if (env.CODE_CHANGED == "true" || imageExists != 0) {
                        echo "🔨 Building new Docker image..."
                        sh "docker build -t ${IMAGE_NAME} ."
                    } else {
                        echo "✅ Using existing image from Docker Hub."
                    }
                }
            }
        }

        stage('Security Scan with Trivy') {
            steps {
                echo "🧪 Running Trivy Security Scan..."
                script {
                    def templatePath = "${TRIVY_TEMPLATE_DIR}/${TRIVY_TEMPLATE_FILE}"
                    def scanCmd = "trivy image --cache-dir ${TRIVY_CACHE_DIR} --skip-db-update --format template --template @${templatePath} -o trivy-report.html --severity HIGH,CRITICAL ${IMAGE_NAME}"

                    def scanStatus = sh(script: """
                        mkdir -p ${TRIVY_CACHE_DIR}
                        echo "🔍 Scanning Docker image for vulnerabilities..."
                        ${scanCmd} || true
                    """, returnStatus: true)

                    archiveArtifacts artifacts: 'trivy-report.html', fingerprint: true

                    if (scanStatus != 0) {
                        echo "🚨 Vulnerabilities detected! Prompting user for action..."
                        def decision = input(
                            id: 'userDecision', message: '⚠ Trivy detected vulnerabilities. Do you want to continue?',
                            parameters: [choice(choices: ['Stop Pipeline', 'Continue Anyway'], description: 'Select an action')]
                        )
                        if (decision == 'Stop Pipeline') {
                            error("🚫 Pipeline stopped due to vulnerabilities.")
                        } else {
                            echo "⚠ Proceeding despite vulnerabilities (user-approved)."
                        }
                    } else {
                        echo "✅ No critical vulnerabilities found!"
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "📤 Pushing image to Docker Hub..."
                sh "docker push ${IMAGE_NAME}"
            }
        }

        stage('Deploy to Test Server') {
            steps {
                echo "🚀 Deploying to Test Server..."
                sshagent(['ssh-test-server']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no bahar@192.168.1.3 '
                        IMAGE_NAME=${IMAGE_NAME}
                        CONTAINER_NAME=${CONTAINER_NAME}

                        echo "🧹 Removing old container if exists..."
                        if [ \$(docker ps -aq -f name=\$CONTAINER_NAME) ]; then
                            docker rm -f \$CONTAINER_NAME
                        fi

                        echo "📦 Pulling latest image from Docker Hub..."
                        docker pull \$IMAGE_NAME

                        echo "🚀 Running container..."
                        docker run -d --name \$CONTAINER_NAME -p 9090:9090 \$IMAGE_NAME

                        echo "✅ Deployment successful on Test Server!"
                    '
                    """
                }
            }
        }

        stage('Smoke Test (Health Check)') {
            steps {
                echo "🩺 Performing Smoke Test on deployed app..."
                script {
                    sh "sleep 5"  // تأخير بسيط لتأكد أن الـ container بدأ
                    def status = sh(script: "curl -o /dev/null -s -w %{http_code} http://192.168.1.3:9090", returnStdout: true).trim()
                    if (status == "200") {
                        echo "✅ Application is healthy and responding correctly!"
                    } else {
                        error("❌ Application failed health check. Status code: ${status}")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully! (Security Scan + Deploy OK)"
            emailext (
                subject: "✅ Jenkins Pipeline Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                <h2>Pipeline Successful 🎉</h2>
                <p>Project: <b>${env.JOB_NAME}</b></p>
                <p>Build Number: <b>${env.BUILD_NUMBER}</b></p>
                <p>View build logs and artifacts:</p>
                <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>
                <hr>
                <p>Attached is the Trivy security scan report.</p>
                """,
                attachLog: false,
                attachmentsPattern: "trivy-report.html",
                mimeType: 'text/html',
                to: "youremail@gmail.com"
            )
        }

        failure {
            echo "❌ Pipeline failed during security scan or deployment. Check logs for details."
            emailext (
                subject: "🚨 Jenkins Pipeline FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                <h2>⚠ Pipeline Failed</h2>
                <p>Project: <b>${env.JOB_NAME}</b></p>
                <p>Build Number: <b>${env.BUILD_NUMBER}</b></p>
                <p>Check Jenkins logs for details:</p>
                <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>
                <hr>
                <p>Attached is the Trivy vulnerability report for review.</p>
                """,
                attachLog: true,
                attachmentsPattern: "trivy-report.html",
                mimeType: 'text/html',
                to: "bahar771379463@gmail.com"
            )
        }
    }
}