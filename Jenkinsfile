pipeline {
  agent any

  stages {
    stage('Clone Repository') {
      steps {
        echo "📥 جاري سحب الكود من GitHub"
        checkout scm
      }
    }

    stage('Build Docker Image') {
      steps {
        echo "⚙ بناء صورة Docker"
        sh '''
          docker build -t myapp:latest .
        '''
      }
    }

    stage('Push to DockerHub') {
      steps {
        echo "🚀 رفع الصورة إلى DockerHub"
        sh '''
          echo "هنا لاحقاً بنضيف أوامر تسجيل الدخول إلى DockerHub"
        '''
      }
    }

    stage('Deploy to Test Server') {
      steps {
        echo "📦 نشر التطبيق إلى سيرفر الاختبار"
        sh '''
          echo "هنا لاحقاً بنضيف أوامر النشر الفعلية"
        '''
      }
    }
  }
}