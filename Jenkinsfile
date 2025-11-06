pipeline {
    agent any

    environment {
        IMAGE_NAME = "bahar771379463/bahar771379:latest"
        CONTAINER_NAME = "dvna"
        GIT_REPO = "https://github.com/bahar771379463-source/devsec-dvna.git"
        GIT_CREDENTIALS = "github-credentials"
        VAULT_ADDR = "http://192.168.1.2:8200"
        VAULT_CREDENTIALS = "vault-root-tokin"
        TRIVY_CACHE_DIR = "/var/lib/trivy"  // 🔐 لتسريع الفحص وتجنب التحميل كل مرة
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
                    ]]
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

        stage('Build Docker Image') {
            steps {
                echo "🔨 Building Docker image..."
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Security Scan with Trivy') {
            steps {
                echo "🧪 Running Trivy Security Scan..."
                sh '''
                mkdir -p ${TRIVY_CACHE_DIR}
                echo "🔍 Scanning Docker image for vulnerabilities..."
                trivy image --cache-dir ${TRIVY_CACHE_DIR} --skip-update --severity HIGH,CRITICAL --exit-code 1 ${IMAGE_NAME} || {
                    echo "🚨 Vulnerabilities found! Stopping pipeline."
                    exit 1
                }
                echo "✅ No critical vulnerabilities found!"
                '''
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
                sshagent(credentials: ['ssh-test-server']) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no bahar@192.168.1.3 "
                        echo '🧹 Removing old container if exists...'
                        if [ \$(docker ps -aq -f name=dvna) ]; then
                            docker rm -f dvna
                        fi

                        echo '📦 Pulling latest image...'
                        docker pull ${IMAGE_NAME}

                        echo '🚀 Running container...'
                        docker run -d --name dvna -p 9090:9090 ${IMAGE_NAME}

                        echo '✅ Deployment successful on Test Server!'
                    "
                    '''
                }
            }
        }

        stage('Smoke Test (Health Check)') {
            steps {
                echo "🩺 Performing Smoke Test on deployed app..."
                script {
                    def response = sh(script: "curl -o /dev/null -s -w %{http_code} http://192.168.1.3:9090", returnStdout: true).trim()
                    if (response != '200') {
                        error("❌ Smoke Test failed! Application did not return HTTP 200.")
                    } else {
                        echo "✅ Smoke Test passed successfully."
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully with Security Scan!"
        }
        failure {
            echo "❌ Pipeline failed during security or deployment stages."
        }
    }
}