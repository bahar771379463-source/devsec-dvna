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
        SNYK_TOKEN="7a0193bc-0276-4282-94ac-80127c3b09c9" 
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

        // 🔐 المرحلة الجديدة: Snyk Security Scan
        stage('Snyk Security Scan') {
            steps {
                script {
                    echo "🧠 Running Snyk vulnerability scan on source code..."
                    
                    withVault([vaultSecrets: [[path: 'secret/snyk-token', secretValues: [
                        [envVar: 'SNYK_TOKEN', vaultKey: 'token']
                    ]]]]) {

                        sh '''
                            if ! command -v snyk >/dev/null 2>&1; then
                                echo "⬇ Installing Snyk CLI..."
                                npm install -g snyk snyk-to-html
                            fi

                            snyk auth ${SNYK_TOKEN}

                            echo "🔍 Scanning source code for vulnerabilities..."
                            snyk test --json > snyk-report.json || true

                            if [ -s snyk-report.json ]; then
                                COUNT=$(jq '[.vulnerabilities[]? | select(.severity=="high" or .severity=="critical")] | length' snyk-report.json)
                            else
                                COUNT=0
                            fi
                            echo $COUNT > snyk-count.txt
                            echo "Found $COUNT HIGH/CRITICAL vulnerabilities."

                            snyk-to-html -i snyk-report.json -o snyk-report.html || true
                        '''

                        def snykCount = readFile('snyk-count.txt').trim()
                        if (!snykCount) { snykCount = "0" }
                        env.SNYK_COUNT = snykCount
                        echo ">> SNYK_COUNT = ${env.SNYK_COUNT}"

                        archiveArtifacts artifacts: 'snyk-report.html', fingerprint: true

                        if (env.SNYK_COUNT != "0") {
                            echo "🚨 Detected ${env.SNYK_COUNT} HIGH/CRITICAL vulnerabilities in code."
                            def choice = input(
                                id: 'snykConfirm',
                                message: "⚠ تم اكتشاف ${env.SNYK_COUNT} ثغرة (High/Critical) من Snyk. هل تريد المتابعة؟",
                                parameters: [
                                    [$class: 'ChoiceParameterDefinition',
                                     choices: "توقف\nاستمرار",
                                     description: 'اختر "توقف" لإيقاف الـ pipeline أو "استمرار" لإكمال المراحل التالية.',
                                     name: 'قرار']
                                ]
                            )
                            if (choice == 'توقف') {
                                error("🛑 تم إيقاف الـ pipeline بناءً على قرار المستخدم بعد Snyk Scan.")
                            } else {
                                echo "✅ تم اختيار الاستمرار بعد Snyk scan رغم وجود ثغرات."
                            }
                        } else {
                            echo "✅ No HIGH/CRITICAL vulnerabilities detected by Snyk."
                        }
                    }
                }
            }
        }

  
       stage('Security Scan with Trivy') {  
    steps {  
        script {  
            sh '''  
                set -eux  
                if ! command -v jq >/dev/null 2>&1; then  
                  apt-get update -y || true  
                  apt-get install -y jq || true  
                fi  
  
                mkdir -p /var/lib/trivy  
  
                echo "🔍 Running Trivy scan (JSON output) ..."  
                trivy image --cache-dir /var/lib/trivy --skip-db-update --format json -o trivy-report.json --severity HIGH,CRITICAL ${IMAGE_NAME} || true  
  
                if [ -s trivy-report.json ]; then  
                  VCOUNT=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH" or .Severity=="CRITICAL")] | length' trivy-report.json)  
                else  
                  VCOUNT=0  
                fi  
                echo $VCOUNT > trivy-vuln-count.txt  
                echo "Found $VCOUNT HIGH/CRITICAL vulnerabilities."  
  
                mkdir -p contrib  
                curl -sSL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl -o contrib/html.tpl  
                trivy image --cache-dir /var/lib/trivy --skip-db-update --format template --template @contrib/html.tpl -o trivy-report.html --severity HIGH,CRITICAL ${IMAGE_NAME} || true  
            '''  
  
            def vcount = readFile('trivy-vuln-count.txt').trim()  
            if (!vcount) { vcount = "0" }  
            env.VULN_COUNT = vcount  
            echo ">> VULN_COUNT = ${env.VULN_COUNT}"  
  
            archiveArtifacts artifacts: 'trivy-report.html', fingerprint: true  
  
            if (env.VULN_COUNT != "0") {  
                echo "🚨 Detected ${env.VULN_COUNT} HIGH/CRITICAL vulnerabilities."  
                def userChoice = input(  
                    id: 'userConfirm',  
                    message: "⚠ Trivy اكتشف ${env.VULN_COUNT} ثغرة(ثغرات) HIGH/CRITICAL. هل تريد المتابعة؟",  
                    parameters: [  
                        [$class: 'ChoiceParameterDefinition',  
                         choices: "توقف\nاستمرار",  
                         description: 'اختر: توقف لإيقاف الـ pipeline، استمرار لتكملة النشر.',  
                         name: 'قرار']  
                    ]  
                )  
                if (userChoice == 'توقف') {  
                    error("🛑 التوقف بناءً على قرار المستخدم (اكتُشفت ${env.VULN_COUNT} ثغرات).")  
                } else {  
                    echo "✅ تم اختيار الاستمرار رغم وجود ${env.VULN_COUNT} ثغرات."  
                }  
            } else {  
                echo "✅ No HIGH/CRITICAL vulnerabilities found."  
            }  
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
              
            emailext(  
                to: "bahar771379463@gmail.com",  
                subject: "✅ Trivy Security Report - Build ${env.BUILD_NUMBER}",  
                body: "Attached is the Trivy and Snyk security scan report for build ${env.BUILD_NUMBER}.",  
                attachmentsPattern: "trivy-report.html, snyk-report.html"  
            )  
  
            script {  
                def report_url = "${env.BUILD_URL}artifact/trivy-report.html"  
                def message = """  
🚀 Pipeline Success!  
✅ Build #${env.BUILD_NUMBER} finished successfully.  
🧩 Project: ${env.JOB_NAME}  
📄 [View Trivy Report](${report_url})  
"""  
                sh """  
                    curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage 
                    -d chat_id=${TELEGRAM_CHAT_ID}  
                    -d parse_mode=Markdown  
                    -d text="${message}"  
                """  
            }  
        }  
  
        failure {  
            echo "❌ Pipeline failed. Check logs for details."  
  
            emailext(  
                to: "bahar771379463@gmail.com",  
                subject: "❌ Build Failed - Security Scan Report",  
                body: "The build ${env.BUILD_NUMBER} failed. Check Jenkins console for details.",  
                attachmentsPattern: "trivy-report.html, snyk-report.html"  
            )  
  
            script {  
                def message = """  
🚨 Pipeline Failed!  
❌ Build #${env.BUILD_NUMBER} has failed.  
🧩 Project: ${env.JOB_NAME}  
🔗 [View Logs](${env.BUILD_URL})  
"""  
                sh """  
                    curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage  
                    -d chat_id=${TELEGRAM_CHAT_ID} 
                    -d parse_mode=Markdown  
                    -d text="${message}"  
                """  
            }  
        }  
    }  
}