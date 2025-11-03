pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "dvna:latest"
        CONTAINER_NAME = "dvna"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "📥 Cloning repository..."
                git branch: 'main',
                    url: 'https://github.com/bahar771379463-source/devsec-dvna.git',
                    credentialsId: 'github-credentials'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🔨 Building Docker image..."
                sh """
                docker build --no-cache -t $DOCKER_IMAGE .
                """
            }
        }

        stage('Run Docker Container') {
            steps {
                echo "▶ Running Docker container..."
                sh """
                    # إزالة أي حاويات قديمة
                    if [ \$(docker ps -aq -f name=$CONTAINER_NAME) ]; then
                        docker rm -f $CONTAINER_NAME
                    fi
                    # تشغيل الحاوية
                    docker run -d --name $CONTAINER_NAME -p 3000:3000 $DOCKER_IMAGE
                """
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