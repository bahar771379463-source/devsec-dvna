pipeline {
    agent any

    environment {
        IMAGE_NAME = "bahar771379463/bahar771379:latest"
        CONTAINER_NAME = "dvna"
        GIT_REPO = "https://github.com/bahar771379463-source/devsec-dvna.git"
        GIT_CREDENTIALS = "github-credentials"
        VAULT_ADDR = "http://192.168.1.2:8200"
        VAULT_CRED = "vault-credentials"

        // 🟢 معلومات بوت تليجرام
        TELEGRAM_TOKEN = "8531739383:AAEZMh8yZL9mODLOau1pufHoMYHKSsDNDtQ"
        TELEGRAM_CHAT_ID = "1469322337"
        SNYK_TOKEN = "7a0193bc-0276-4282-94ac-80127c3b09c9"
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
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
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
                sh "docker pull ${IMAGE_NAME} || true"
            }
        }

        stage('Snyk Security Scan') {
            steps {
                script {
                    echo "🧠 Running Snyk vulnerability scan on source code..."
                    sh """
                        if ! command -v snyk >/dev/null 2>&1; then
                            echo "⬇ Installing Snyk CLI..."
                            npm install -g snyk snyk-to-html || true
                        fi

                        snyk auth ${SNYK_TOKEN}
                        snyk test --json > snyk-report.json || true
                        if [ -s snyk-report.json ]; then
                            COUNT=\$(jq '[.vulnerabilities[]? | select(.severity=="high" or .severity=="critical")] | length' snyk-report.json)
                        else
                            COUNT=0
                        fi
                        echo \$COUNT > snyk-count.txt
                        snyk-to-html -i snyk-report.json -o snyk-report.html || true
                    """
                    env.SNYK_COUNT = readFile('snyk-count.txt').trim()
                    archiveArtifacts artifacts: 'snyk-report.html', fingerprint: true
                }
            }
        }

        stage('Security Scan with Trivy') {
            steps {
                script {
                    sh '''
                        set -eux
                        mkdir -p /var/lib/trivy

                        trivy image --cache-dir /var/lib/trivy --skip-db-update --format json -o trivy-report.json --severity HIGH,CRITICAL ${IMAGE_NAME} || true

                        if [ -s trivy-report.json ]; then
                          VCOUNT=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH" or .Severity=="CRITICAL")] | length' trivy-report.json)
                        else
                          VCOUNT=0
                        fi
                        echo $VCOUNT > trivy-vuln-count.txt

                        mkdir -p contrib
                        curl -sSL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl -o contrib/html.tpl
                        trivy image --cache-dir /var/lib/trivy --skip-db-update --format template --template @contrib/html.tpl -o trivy-report.html --severity HIGH,CRITICAL ${IMAGE_NAME} || true
                    '''
                    env.VULN_COUNT = readFile('trivy-vuln-count.txt').trim()
                    archiveArtifacts artifacts: 'trivy-report.html', fingerprint: true
                }
            }
        }

        stage('Generate Unified Security Report') {
            steps {
                script {
                    sh '''
                        HIGH_T=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length' trivy-report.json 2>/dev/null || echo 0)
                        CRIT_T=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy-report.json 2>/dev/null || echo 0)
                        HIGH_S=$(jq '[.vulnerabilities[]? | select(.severity=="high")] | length' snyk-report.json 2>/dev/null || echo 0)
                        CRIT_S=$(jq '[.vulnerabilities[]? | select(.severity=="critical")] | length' snyk-report.json 2>/dev/null || echo 0)
                        TOTAL_T=$((HIGH_T + CRIT_T))
                        TOTAL_S=$((HIGH_S + CRIT_S))
                        BUILD_DATE=$(date "+%Y-%m-%d %H:%M:%S")
                        PROJECT_NAME="${JOB_NAME:-Unknown}"
                        BUILD_NUM="${BUILD_NUMBER:-N/A}"

                        echo "<html><head><title>Unified Security Report</title>
                        <style>
                            body { font-family: Arial; background:#f9f9f9; color:#333; padding:20px; }
                            table { border-collapse: collapse; width: 60%; margin:auto; background:#fff; box-shadow: 0 0 10px rgba(0,0,0,0.1);}
                            th, td { border: 1px solid #ccc; padding: 10px; text-align: center; }
                            th { background: #333; color: #fff; }
                            h1, h2 { text-align: center; }
                            iframe { border: none; width: 100%; height: 600px; margin-top: 10px; }
                            .meta { font-size:14px; color:#555; text-align:center; margin-bottom:20px; }
                        </style></head><body>" > security-summary.html

                        echo "<h1>🧾 Unified Security Report</h1>
                              <div class='meta'><b>Project:</b> ${PROJECT_NAME} | <b>Build:</b> #${BUILD_NUM} | <b>Date:</b> ${BUILD_DATE}</div>" >> security-summary.html

                        echo "<table>
                                <tr><th>Tool</th><th>High</th><th>Critical</th><th>Total</th></tr>
                                <tr><td>Snyk</td><td>$HIGH_S</td><td>$CRIT_S</td><td>$TOTAL_S</td></tr>
                                <tr><td>Trivy</td><td>$HIGH_T</td><td>$CRIT_T</td><td>$TOTAL_T</td></tr>
                              </table><hr>" >> security-summary.html

                        echo "<h2>Snyk Report</h2>" >> security-summary.html
                        [ -f snyk-report.html ] && echo "<iframe src='snyk-report.html'></iframe>" >> security-summary.html || echo "<p>No Snyk report found.</p>" >> security-summary.html

                        echo "<h2>Trivy Report</h2>" >> security-summary.html
                        [ -f trivy-report.html ] && echo "<iframe src='trivy-report.html'></iframe>" >> security-summary.html || echo "<p>No Trivy report found.</p>" >> security-summary.html

                        echo "</body></html>" >> security-summary.html
                    '''
                    archiveArtifacts artifacts: 'security-summary.html', fingerprint: true
                }
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
                    sh """
ssh -o StrictHostKeyChecking=no bahar@192.168.1.3 '
OLD_CONTAINERS=\$(docker ps -aq -f name=${CONTAINER_NAME})
if [ ! -z "\$OLD_CONTAINERS" ]; then
    echo "🧹 Removing old container(s)..."
    docker rm -f \$OLD_CONTAINERS
fi

echo "📦 Pulling latest image..."
docker pull ${IMAGE_NAME}

echo "🚀 Running container..."
docker run -d --name ${CONTAINER_NAME} -p 9090:9090 ${IMAGE_NAME}
'
                    """
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
            echo "✅ Pipeline completed successfully!"
            emailext(
                to: "bahar771379463@gmail.com",
                subject: "✅ Security Report - Build ${env.BUILD_NUMBER}",
                body: "Attached is the Trivy and Snyk unified security report for build ${env.BUILD_NUMBER}.",
                attachmentsPattern: "security-summary.html,snyk-report.html,trivy-report.html"
            )

            script {
                def report_url = "${env.BUILD_URL}artifact/security-summary.html"
                def message = """
🚀 Pipeline Success!
✅ Build #${BUILD_NUMBER} finished successfully.
🧩 Project: ${JOB_NAME}
📄 [View Unified Security Report](${report_url})
"""
                sh """
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \\
--data-urlencode 'chat_id=${TELEGRAM_CHAT_ID}' \\
--data-urlencode 'parse_mode=Markdown' \\
--data-urlencode 'text=${message}'
"""
            }
        }

        failure {
            echo "❌ Pipeline failed."
            emailext(
                to: "bahar771379463@gmail.com",
                subject: "❌ Build Failed - Security Scan Report",
                body: "The build ${env.BUILD_NUMBER} failed. Check Jenkins console for details.",
                attachmentsPattern: "security-summary.html,snyk-report.html,trivy-report.html"
            )

            script {
                def message = """
🚨 Pipeline Failed!
❌ Build #${BUILD_NUMBER} has failed.
🧩 Project: ${JOB_NAME}
🔗 [View Logs](${env.BUILD_URL})
"""
                sh """
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \\
--data-urlencode 'chat_id=${TELEGRAM_CHAT_ID}' \\
--data-urlencode 'parse_mode=Markdown' \\
--data-urlencode 'text=${message}'
"""
            }
        }
    }
}