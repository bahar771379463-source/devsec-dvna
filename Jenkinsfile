pipeline {
    agent any

    environment {
        IMAGE_NAME = "bahar771379463/bahar771379:latest"
        NAME = "dvna"
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

        withVault([
            vaultSecrets: [
                [
                    path: 'secret/docker-credentials',   // تأكد أن هذا المسار موجود فعلاً في Vault
                    secretValues: [
                        [envVar: 'DOCKERHUB_USER', vaultKey: 'username'],
                        [envVar: 'DOCKERHUB_PASS', vaultKey: 'password']
                    ]
                ]
            ],
            configuration: [
                vaultUrl: 'http://192.168.1.2:8200',      // غيّر هذا حسب IP سيرفر Vault
                vaultCredentialId: 'vault-root-tokin'      // الـ AppRole المربوط في Jenkins
            ]
        ]) {
            echo "✅ Credentials loaded from Vault."

            sh '''
            echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
            '''
        }
    }
}


        stage('Check for Code Changes') {
            steps {
                script {
                    echo "🔍 Checking for code or Dockerfile changes..."
                    def changed = sh(script: '''
                        git diff --name-only HEAD~1 HEAD | grep -E "(Dockerfile|package.json|package-lock.json|src|app|server.js)" || true
                    ''', returnStdout: true).trim()

                    if (changed) {
                        echo "🟡 Detected code changes:\n${changed}"
                        env.CHANGED = "true"
                    } else {
                        echo "🟢 No code changes detected."
                        env.CHANGED = "false"
                    }
                }
            }
        }

        stage('Compare Docker Image Digests') {
            steps {
                script {
                    echo "🔎 Comparing local and remote image digests..."
                    sh "docker pull ${IMAGE_NAME} || true"

                    def localDigest = sh(script: "docker inspect --format='{{index .RepoDigests 0}}' ${IMAGE_NAME} || true", returnStdout: true).trim()
                    def remoteDigest = sh(script: "docker manifest inspect ${IMAGE_NAME} --verbose | grep -m1 digest | awk '{print \$2}' | tr -d '\"'", returnStdout: true).trim()

                    if (localDigest && remoteDigest && localDigest == remoteDigest) {
                        echo "🟢 Local image matches remote digest. No rebuild needed."
                        env.SAME_IMAGE = "true"
                    } else {
                        echo "🟡 Image difference detected or missing locally."
                        env.SAME_IMAGE = "false"
                    }
                }
            }
        }

        stage('Build Docker Image (with Cache)') {
            when {
                expression { env.CHANGED == "true" || env.SAME_IMAGE == "false" }
            }
            steps {
                echo "🔨 Building new Docker image using cache..."
                sh '''
                    echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
                    docker pull ${IMAGE_NAME} || true
                    docker build --cache-from ${IMAGE_NAME} -t ${IMAGE_NAME} .
                    docker logout
                '''
            }
        }

        stage('Push to Docker Hub') {
            when {
                expression { env.CHANGED == "true" || env.SAME_IMAGE == "false" }
            }
            steps {
                echo "📦 Pushing updated image to Docker Hub..."
                sh '''
                    echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
                    docker push ${IMAGE_NAME}
                    docker logout
                '''
            }
        }

        stage('Run Docker Container') {
            steps {
                echo "🚀 Deploying container..."
                sh '''
                    docker rm -f ${NAME} || true
                    docker run -d --name ${NAME} -p 9090:9090 ${IMAGE_NAME}
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
