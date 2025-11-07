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
    }

    stages {

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

        // 🌟 المرحلة الأمنية الجديدة مع تفاعل
        stage('Security Scan with Trivy') {
            steps {
                echo "🧪 Running Trivy Security Scan..."
                script {
                    def scanStatus = sh(script: """
                        mkdir -p ${TRIVY_CACHE_DIR}
                        echo "🔍 Scanning Docker image for vulnerabilities..."
                        trivy image --cache-dir ${TRIVY_CACHE_DIR} --skip-db-update \
                        --format template --template "@contrib/html.tpl" -o trivy-report.html \
                        --severity HIGH,CRITICAL ${IMAGE_NAME} || true
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
                    sh '''
                    ssh -o StrictHostKeyChecking=no bahar@192.168.1.3 '
                        echo "🧹 Removing old container if exists..."
                        if [ $(docker ps -aq -f name=dvna) ]; then
                            docker rm -f dvna
                        fi

                        echo "📦 Pulling latest image from Docker Hub..."
                        docker pull ${IMAGE_NAME}

                        echo "🚀 Running container..."
                        docker run -d --name dvna -p 9090:9090 ${IMAGE_NAME}

                        echo "✅ Deployment successful on Test Server!"
                    '
                    '''
                }
            }
        }

        stage('Smoke Test (Health Check)') {
            steps {
                echo "🩺 Performing Smoke Test on deployed app..."
                script {
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
                <p>Attached is the Trivy security scan report (HTML).</p>
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
                to: "youremail@gmail.com"
            )
        }
    }
}