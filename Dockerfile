FROM node:16-bullseye

# تحديد مجلد العمل
WORKDIR /app

# نسخ ملفات package.json و package-lock.json أولًا لتسريع التخزين المؤقت
COPY package*.json ./

# تثبيت الأدوات اللازمة للبناء وحزم npm
RUN apt-get update && \
    apt-get install -y python3 make g++ libxml2-dev && \
    npm install -g npm@latest && \
    npm install

# نسخ باقي ملفات المشروع
COPY . .

# تعيين الأمر الافتراضي لتشغيل المشروع
CMD ["npm", "start"]