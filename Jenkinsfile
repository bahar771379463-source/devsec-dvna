pipeline {
    agent any

    environment {
        IMAGE_NAME = "dvna"
        CONTAINER_NAME = "dvna"
        DOCKERHUB_USER = "bahar771379463"  // غيّرها لو حسابك غير هذا
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📥 Cloning repository...'
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/bahar771379463-source/devsec-dvna.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🔨 Building Docker image...'
                sh 'docker build -t ${IMAGE_NAME}:latest .'
            }
        }

        stage('Run Container') {
            steps {
                echo '🚀 Running container...'
                // احذف الحاوية القديمة إن وجدت
                sh '''
                    docker rm -f ${CONTAINER_NAME} || true
                    docker run -d -p 9090:9090 --name ${CONTAINER_NAME} ${IMAGE_NAME}:latest npm start
                '''
            }
        }

        stage('Verify') {
            steps {
                echo '🧪 Verifying container status...'
                sh 'sleep 5'
                sh 'docker ps'
                sh 'curl -I http://localhost:9090 || true'
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up...'
            sh 'docker rm -f ${CONTAINER_NAME} || true'
        }
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs for details.'
        }
    }
}