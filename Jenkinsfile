pipeline {
    agent any

    environment {
        IMAGE_NAME = "dvna:latest"
        NAME = "dvna"
        GIT_REPO = "https://github.com/bahar771379463-source/devsec-dvna.git"
        GIT_CREDENTIALS = "github-credentials"
        VAULT_ADDR = "http://192.168.1.2:8200"    
        VAULT_CRED = "vault-root-tokin"             
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "📥 Cloning repository..."
                git branch: 'main', url: "${GIT_REPO}", credentialsId: "${GIT_CREDENTIALS}"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🔨 Building Docker image..."
                sh '''
                docker build -t ${IMAGE_NAME} . || exit 1
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "🔐 Fetching Docker Hub credentials from Vault..."
                withVault(configuration: [vaultUrl: "${VAULT_ADDR}",
                                          vaultCredentialId: "${VAULT_CRED}",
                                          engineVersion: 2],
                          vaultSecrets: [[path: 'secret/docker-credentials',
                                          secretValues: [
                                              [envVar: 'DOCKER_USER', vaultKey: 'username'],
                                              [envVar: 'DOCKER_PASS', vaultKey: 'password']
                                          ]]
                         ]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    docker tag ${IMAGE_NAME} bahar771379463/bahar771379:latest
                    docker push bahar771379463/bahar771379:latest
                    docker logout
                    '''
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                echo "▶ Running Docker container..."
                sh '''
                if [ $(docker ps -aq -f name=${NAME}) ]; then
                    docker rm -f ${NAME}
                fi

                docker run -d --name ${NAME} -p 9090:9090 bahar771379463/bahar771379:latest
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