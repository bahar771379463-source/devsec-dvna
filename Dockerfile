FROM node:16-bullseye

# إعداد بيئة العمل
WORKDIR /app

# نسخ الملفات
COPY package*.json ./
COPY . .

# تحديث النظام وتثبيت أدوات البناء
RUN apt-get update && apt-get install -y python3 make g++ \
    && npm uninstall libxmljs \
    && npm install libxmljs2 \
    && npm install \
    && chmod +x /app/entrypoint.sh

# فتح المنفذ
EXPOSE 9090

# أمر التشغيل
CMD ["npm", "start"]