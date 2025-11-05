pipeline {
    agent any

    environment {
        IMAGE_NAME = "bahar771379463/bahar771379:latest"
        CONTAINER_NAME = "dvna"
        GIT_REPO = "https://github.com/bahar771379463-source/devsec-dvna.git"
        GIT_CREDENTIALS = "github-credentials"
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
                withVault(configuration: [vaultUrl: 'http://192.168.1.2:8200',
                                          vaultCredentialId: 'vault-root-tokin'], 
                          vaultSecrets: [[path: 'secret/docker-credentials', secretValues: [
                              [envVar: 'DOCKERHUB_USER', vaultKey: 'username'],
                              [envVar: 'DOCKERHUB_PASS', vaultKey: 'password']
                          ]]]
                ) {
                    echo "✅ Credentials loaded from Vault."
                }
            }
        }

        stage('Build or Pull Docker Image') {
            steps {
                echo "⚙ Checking if image exists in Docker Hub..."
                sh '''
                if docker pull ${IMAGE_NAME}; then
                  echo "🟢 Using existing image from Docker Hub."
                else
                  echo "🔨 Building new Docker image..."
                  docker build -t ${IMAGE_NAME} .
                  echo "${DOCKERHUB_PASS}" | docker login -u "${DOCKERHUB_USER}" --password-stdin
                  docker push ${IMAGE_NAME}
                fi
                '''
            }
        }

        stage('Run Docker Container') {
            steps {
                echo "🚀 Deploying container..."
                sh '''
               # حذف كل الحاويات اللي تحمل الاسم بالضبط (وليس أي جزئية منه)
                if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
                echo "🧹 Removing old container ${CONTAINER_NAME}..."
                    docker rm -f ${CONTAINER_NAME}
                    fi
                # تشغيل الحاوية
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
