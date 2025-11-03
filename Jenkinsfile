pipeline {
    agent any

    environment {
        // اسم الصورة التي سنبنيها
        DOCKER_IMAGE = "dvna:latest"
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
                    docker build -t $DOCKER_IMAGE .
                """
            }
        }

        stage('Run Docker Container') {
            steps {
                echo "▶ Running Docker container..."
                sh """
                    # تحقق من عدم وجود حاويات قديمة
                    if [ \$(docker ps -aq -f name=dvna-container) ]; then
                        docker rm -f dvna-container
                    fi
                    # تشغيل الحاوية
                    docker run -d --name dvna-container -p 3000:3000 $DOCKER_IMAGE
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