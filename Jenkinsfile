pipeline {
    agent any

    environment {
        APP_NAME = "dvna"
        APP_PORT = "9090"
    }

    stages {

        stage('🧹 Clean Up Old Container') {
            steps {
                echo "🔄 إزالة أي حاويات قديمة..."
                sh '''
                    docker stop $APP_NAME || true
                    docker rm -f $APP_NAME || true
                '''
            }
        }

        stage('🧱 Build Docker Image') {
            steps {
                echo "🏗 جاري بناء الصورة من المجلد المحلي..."
             {
                    sh '''
                        docker build -t ${APP_NAME}:latest .
                    '''
                }
            }
        }

        stage('🚀 Run Container') {
            steps {
                echo "🚀 تشغيل الحاوية الآن..."
                sh '''
                    docker run -d -p ${APP_PORT}:9090 --name ${APP_NAME} ${APP_NAME}:latest
                '''
            }
        }

        stage('✅ Verify Running') {
            steps {
                echo "🔍 التحقق من أن الحاوية تعمل..."
                sh '''
                    docker ps | grep ${APP_NAME} || (echo "❌ الحاوية لم تعمل!" && exit 1)
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 تم بناء وتشغيل DVNA بنجاح على المنفذ ${APP_PORT}"
        }
        failure {
            echo "❌ حدث خطأ أثناء البناء أو التشغيل"
        }
    }
}