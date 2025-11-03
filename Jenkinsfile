pipeline {
    agent any

    environment {
        IMAGE_NAME = "dvna:latest"
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

        stage('Build Docker Image') {
            steps {
                echo "🔨 Building Docker image..."
                sh '''
                docker build --no-cache -t ${IMAGE_NAME} . || exit 1
                '''
            }
        }

        stage('Run Docker Container') {
            steps {
                echo "▶ Running Docker container..."
                sh '''
                # حذف أي حاوية موجودة باسم ${NAME}
                if [ $(docker ps -aq -f name=${NAME}) ]; then
                    docker rm -f ${NAME}
                fi

                # تشغيل الحاوية الجديدة
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