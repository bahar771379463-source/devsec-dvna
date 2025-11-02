pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo '📥 Cloning repository...'
                git 'https://github.com/bahar771379463-source/devsec-dvna.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🛠 Building Docker image...'
                sh 'docker build -t dvna:latest .'
            }
        }

        stage('Run Container') {
            steps {
                echo '🚀 Running DVNA container...'
                sh 'docker run -d -p 9090:9090 --name dvna dvna:latest'
            }
        }

        stage('Verify') {
            steps {
                echo '✅ Verifying container...'
                sh 'docker ps'
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up...'
            sh 'docker rm -f dvna || true'
        }
    }
}