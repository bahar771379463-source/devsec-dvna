FROM node:16-bullseye

# إعداد مجلد العمل داخل الحاوية
WORKDIR /app

# نسخ ملفات package.json و package-lock.json
COPY package*.json ./

# تحديث النظام وتثبيت أدوات البناء
RUN apt-get update && apt-get install -y python3 make g++

# إعداد NPM لتفادي مشاكل الشبكة أو الـ timeout
RUN npm config set fetch-timeout 600000 \
    && npm config set fetch-retries 5 

# إزالة libxmljs القديم (لو موجود) وتثبيته من جديد
RUN npm uninstall libxmljs || true \
    && npm install libxmljs


# تثبيت باقي الاعتمادات
RUN npm install

# نسخ باقي ملفات المشروع
COPY . .

# منح صلاحيات التنفيذ للملف entrypoint.sh (لو موجود)
RUN chmod +x /app/entrypoint.sh || true

# فتح المنفذ الخاص بالتطبيق
EXPOSE 9090

# تشغيل التطبيق
CMD ["npm", "start"]