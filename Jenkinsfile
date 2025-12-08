pipeline {
    agent any

    environment {    
        IMAGE_NAME = "bahar771379463/bahar771379:latest"    
        CONTAINER_NAME = "dvna"    
        GIT_REPO = "https://github.com/bahar771379463-source/devsec-dvna.git"    
        GIT_CREDENTIALS = "github-credentials"    
        VAULT_ADDR = "http://192.168.1.2:8200"    
        VAULT_CRED = "vault-credentials"    

        TELEGRAM_TOKEN = "8531739383:AAEZMh8yZL9mODLOau1pufHoMYHKSsDNDtQ"    
        TELEGRAM_CHAT_ID = "1469322337"  
        SNYK_TOKEN="7a0193bc-0276-4282-94ac-80127c3b09c9"
    }    

    stages {

        /* ============================
           1. CHECKOUT
           ============================ */
        stage('Checkout SCM') {    
            steps {    
                git branch: 'main', url: "${GIT_REPO}", credentialsId: "${GIT_CREDENTIALS}"    
            }    
        }    

        /* ============================
           2. Initialize Trivy Template
           ============================ */
        stage('Initialize Trivy Template') {    
            steps {    
                sh '''
                    mkdir -p contrib /var/lib/trivy  
                    curl -sSL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl -o contrib/html.tpl    
                '''    
            }    
        }    

        /* ============================
           3. Fetch DockerHub Credentials
           ============================ */
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

        /* ============================
           4. Build or Pull Image
           ============================ */
        stage('Build or Use Existing Image') {    
            steps {    
                sh "docker pull ${IMAGE_NAME} || true"    
            }    
        }    

        /* ============================
           5. Security Scans (Snyk & Trivy)
           ============================ */
        stage('Snyk Security Scan') {  
            steps {  
                script {  
                    sh '''
                        npm install -g snyk snyk-to-html || true
                        snyk auth ${SNYK_TOKEN}
                        snyk test --json > snyk-report.json || true
                        snyk-to-html -i snyk-report.json -o snyk-report.html || true
                    '''
                }  
            }  
        }  

        stage('Security Scan with Trivy') {    
            steps {    
                script {    
                    sh '''
                        trivy image --format json -o trivy-report.json --severity HIGH,CRITICAL ${IMAGE_NAME} || true
                        trivy image --format template --template @contrib/html.tpl -o trivy-report.html ${IMAGE_NAME} || true
                    '''
                }    
            }    
        }    

        /* ============================
           6. Approval BEFORE Test Deployment
           ============================ */
        stage("Approval Before Test") {
            steps {
                input message: "❓ هل تريد الاستمرار إلى نشر النسخة في بيئة TEST ؟", ok: "نعم استمر"
            }
        }

        /* ============================
           7. Deploy to TEST Server
           ============================ */
        stage('Deploy to Test Server') {    
            steps {    
                sshagent(credentials: ['ssh-test-server']) {    
                    sh '''
ssh -o StrictHostKeyChecking=no bahar@192.168.1.3 '
docker rm -f dvna || true
docker pull bahar771379463/bahar771379:latest
docker run -d --name dvna -p 9090:9090 bahar771379463/bahar771379:latest
'
'''
                }
            }    
        }

        /* ============================
           8. Send Email AFTER Test 
           ============================ */
        stage("Send Email After Test") {
            steps {
                emailext(
                    to: "bahar771379463@gmail.com",
                    subject: "🚀 TEST Deployment Completed - Build ${BUILD_NUMBER}",
                    body: "تم نشر النسخة إلى بيئة TEST بنجاح!"
                )
            }
        }

        /* ============================
           9. Approval BEFORE Production
           ============================ */
        stage("Approval Before PRODUCTION") {
            steps {
                input message: "⚠️ هل تريد نشر النسخة في بيئة PRODUCTION ؟", ok: "نعم استمر"
            }
        }

        /* ============================
           10. Deploy to PRODUCTION
           ============================ */
        stage('Deploy to Production Server') {    
            steps {    
                sshagent(credentials: ['ssh-prod-server']) {    
                    sh '''
ssh -o StrictHostKeyChecking=no bahar@192.168.1.4 '
docker rm -f dvna || true
docker pull bahar771379463/bahar771379:latest
docker run -d --name dvna -p 9091:9091 bahar771379463/bahar771379:latest
'
'''
                }
            }    
        }

        /* ============================
           11. Email AFTER Production
           ============================ */
        stage("Send Email After PRODUCTION") {
            steps {
                emailext(
                    to: "bahar771379463@gmail.com",
                    subject: "🎉 PRODUCTION Deployment Completed!",
                    body: "تم نشر النسخة في الإنتاج بنجاح على المنفذ 9091."
                )
            }
        }
    }

    /* ============================
       POST BLOCK (Success/Failure)
       ============================ */
    post {

        success {
            script {
                sh """
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
--data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
--data-urlencode "text=✔️ SUCCESS: Deployment completed successfully!"
"""
            }
        }

        failure {
            script {
                sh """
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
--data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
--data-urlencode "text=❌ FAILURE: Pipeline failed!"
"""
            }
        }
    }
}