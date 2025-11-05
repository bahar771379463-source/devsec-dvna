pipeline {
    agent any

    environment {
        IMAGE_NAME = "bahar771379463/bahar771379:latest"
        CONTAINER_NAME = "dvna"
        GIT_REPO = "https://github.com/bahar771379463-source/devsec-dvna.git"
        GIT_CREDENTIALS = "github-credentials"
        VAULT_ADDR = "http://192.168.1.2:8200"
        VAULT_CREDENTIALS = "vault-root-tokin"
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
                withVault([vaultSecrets: [
                    [path: 'secret/docker-credentials',
                     secretValues: [
                         [envVar: 'DOCKERHUB_USER', vaultKey: 'username'],
                         [envVar: 'DOCKERHUB_PASS', vaultKey: 'password']
                     ]]
                ]]) {
                    echo "✅ Credentials loaded from Vault."

                    // اختبار الاتصال بالإنترنت
                    sh '''
                    echo "🌐 Testing connection to Docker Hub..."
                    curl -I --max-time 10 https://registry-1.docker.io/v2/ || true
                    '''

                    // تسجيل الدخول مع 3 محاولات
                    sh '''
                    echo "🔑 Attempting Docker login..."
                    for i in {1..3}; do
                        echo "${DOCKERHUB_PASS}" | docker login -u "${DOCKERHUB_USER}" --password-stdin && break
                        echo "⚠️ Login failed... retrying in 10 seconds..."
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

        stage('Push to Docker Hub') {
            steps {
                echo "📤 Pushing image to Docker Hub..."
                sh '''
                docker push ${IMAGE_NAME}
                '''
            }
        }

        stage('Run Docker Container') {
            steps {
                echo "🚀 Deploying container..."
                sh '''
                # حذف أي حاوية سابقة بنفس الاسم
                if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
                    docker rm -f ${CONTAINER_NAME}
                fi

                # تشغيل الحاوية الجديدة
                docker run -d --name ${CONTAINER_NAME} -p 9090:9090 ${IMAGE_NAME}
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs for details."
        }
    }
}
