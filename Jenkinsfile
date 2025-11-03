pipeline {
    agent any

    environment {
        IMAGE_NAME = "dvna:latest"
        CONTAINER_NAME = "dvna"
    }

    stages {
        stage('Preparation') {
            steps {
                echo "🔧 Cleaning old containers and images if exist..."
                sh '''
                    docker rm -f $CONTAINER_NAME || true
                    docker rmi -f $IMAGE_NAME || true
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('dvna') { // نضمن أن Jenkins داخل مجلد المشروع الصحيح
                    echo "🚧 Building Docker image..."
                    sh 'docker build -t $IMAGE_NAME .'
                }
            }
        }

        stage('Run Container') {
            steps {
                echo "🚀 Running DVNA container..."
                sh '''
                    docker run -d --name $CONTAINER_NAME -p 9090:9090 $IMAGE_NAME
                '''
            }
        }

        stage('Verify') {
            steps {
                echo "✅ Checking if container is running..."
                sh 'docker ps | grep dvna || (echo "DVNA not running!" && exit 1)'
            }
        }
    }

    post {
        success {
            echo "🎉 DVNA is up and running at http://<your-server-ip>:9090"
        }
        failure {
            echo "❌ Build or run failed. Check logs above."
        }
    }
}