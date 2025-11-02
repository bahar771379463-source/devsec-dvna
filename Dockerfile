FROM node:20-bullseye

# إعداد مجلد العمل داخل الحاوية
WORKDIR /app

# نسخ ملفات المشروع
COPY . .

# تحديث النظام وتثبيت الأدوات اللازمة للبناء
RUN apt-get update && apt-get install -y python3 make g++ && \
    rm -rf /var/lib/apt/lists/*

# حذف libxmljs القديم وتثبيت النسخة الحديثة الآمنة


# التأكد من أن السكربت التنفيذي قابل للتشغيل
RUN chmod +x /app/entrypoint.sh

# تثبيت بقية الاعتمادات
RUN npm install

# فتح المنفذ 9090
EXPOSE 9090

# تشغيل التطبيق
CMD ["npm", "start"]