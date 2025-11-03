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
                docker ps -aq -f name=dvna | grep . && docker rm -f dvna || echo "No container to remove"
                    docker run -d --name dvna -p 3000:3000 dvna:latest
                    
               
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