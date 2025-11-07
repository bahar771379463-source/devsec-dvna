pipeline {
    agent any

    environment {
        IMAGE_NAME = "bahar771379463/bahar771379:latest"
        CONTAINER_NAME = "dvna"
        GIT_REPO = "https://github.com/bahar771379463-source/devsec-dvna.git"
        GIT_CREDENTIALS = "github-credentials"
        VAULT_ADDR = "http://192.168.1.2:8200"
        VAULT_CRED = "vault-credentials"

        // 🟢 أضف معلومات بوت تليجرام هنا
        TELEGRAM_TOKEN = "8531739383:AAEZMh8yZL9mODLOau1pufHoMYHKSsDNDtQ"
        TELEGRAM_CHAT_ID = "1469322337"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git branch: 'main', url: "${GIT_REPO}", credentialsId: "${GIT_CREDENTIALS}"
            }
        }

        stage('Initialize Trivy Template') {
            steps {
                sh '''
                    mkdir -p contrib
                    curl -sSL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl -o contrib/html.tpl
                '''
            }
        }

        stage('Fetch DockerHub Credentials from Vault') {
            steps {
                withVault([vaultSecrets: [[path: 'secret/docker-credentials', secretValues: [
                    [envVar: 'DOCKER_USER', vaultKey: 'username'],
                    [envVar: 'DOCKER_PASS', vaultKey: 'password']
                ]]]]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    '''
                }
            }
        }

        stage('Check for Code Changes') {
            steps {
                script {
                    def changes = sh(script: "git diff --name-only HEAD~1 HEAD | grep -E '(Dockerfile|package.json|src|server.js)' || true", returnStdout: true).trim()
                    if (changes) {
                        echo "🔍 Code changes detected, will build a new image."
                    } else {
                        echo "🟢 No code changes detected."
                    }
                }
            }
        }

        stage('Build or Use Existing Image') {
            steps {
                script {
                    sh "docker pull ${IMAGE_NAME} || true"
                }
            }
        }

        stage('Security Scan with Trivy') {
            steps {
                script {
                    sh '''
                        mkdir -p /var/lib/trivy
                        echo "🔍 Scanning Docker image for vulnerabilities..."
                        trivy image --cache-dir /var/lib/trivy --skip-db-update --format template --template @contrib/html.tpl -o trivy-report.html --severity HIGH,CRITICAL ${IMAGE_NAME}
                    '''
                }
                archiveArtifacts artifacts: 'trivy-report.html', fingerprint: true
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh "docker push ${IMAGE_NAME}"
            }
        }

        stage('Deploy to Test Server') {
            steps {
                sshagent(credentials: ['ssh-test-server']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no bahar@192.168.1.3 "
                        echo '🧹 Removing old container if exists...'
                        if [ $(docker ps -aq -f name=${CONTAINER_NAME}) ]; then
                            docker rm -f ${CONTAINER_NAME}
                        fi
                        echo '📦 Pulling latest image from Docker Hub...'
                        docker pull ${IMAGE_NAME}
                        echo '🚀 Running container...'
                        docker run -d --name ${CONTAINER_NAME} -p 9090:9090 ${IMAGE_NAME}
                        echo '✅ Deployment successful on Test Server!'
                        "
                    '''
                }
            }
        }

        stage('Smoke Test (Health Check)') {
            steps {
                script {
                    sleep 5
                    def status = sh(script: "curl -o /dev/null -s -w %{http_code} -L http://192.168.1.3:9090", returnStdout: true).trim()
                    if (status == "200") {
                        echo "✅ Application is healthy (status: ${status})"
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
            
            // إرسال التقرير إلى البريد الإلكتروني
            emailext(
                to: "bahar771379463@gmail.com",
                subject: "✅ Trivy Security Report - Build ${env.BUILD_NUMBER}",
                body: "Attached is the Trivy security scan report for build ${env.BUILD_NUMBER}.",
                attachmentsPattern: "trivy-report.html"
            )

            // إرسال إشعار إلى تليجرام مع رابط التقرير
            script {
                def report_url = "${env.BUILD_URL}artifact/trivy-report.html"
                def message = """
🚀 Pipeline Success!
✅ Build #${env.BUILD_NUMBER} finished successfully.
🧩 Project: ${env.JOB_NAME}
📄 [View Trivy Report](${report_url})
"""
                sh """
                    curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage \
                    -d chat_id=${TELEGRAM_CHAT_ID} \
                    -d parse_mode=Markdown \
                    -d text="${message}"
                """
            }
        }

        failure {
            echo "❌ Pipeline failed. Check logs for details."

            // إشعار البريد
            emailext(
                to: "bahar771379463@gmail.com",
                subject: "❌ Build Failed - Trivy Security Report",
                body: "The build ${env.BUILD_NUMBER} failed. Check Jenkins console for details.",
                attachmentsPattern: "trivy-report.html"
            )

            // إشعار تليجرام عند الفشل
            script {
                def message = """
🚨 Pipeline Failed!
❌ Build #${env.BUILD_NUMBER} has failed.
🧩 Project: ${env.JOB_NAME}
🔗 [View Logs](${env.BUILD_URL})
"""
                sh """
                    curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage \
                    -d chat_id=${TELEGRAM_CHAT_ID} \
                    -d parse_mode=Markdown \
                    -d text="${message}"
                """
            }
        }
    }
}