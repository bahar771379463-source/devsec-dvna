FROM node:20-bullseye

# تحديد مجلد العمل
WORKDIR /app

# نسخ ملفات package.json و package-lock.json أولًا
COPY package*.json ./

# تثبيت الأدوات اللازمة للبناء وحزم npm
# ملاحظة: لا نقوم بترقية npm لتجنب مشاكل engine
RUN apt-get update && \
    apt-get install -y python3 make g++ libxml2-dev && \
    npm install

# نسخ باقي ملفات المشروع
COPY . .

# أمر التشغيل الافتراضي
CMD ["npm", "start"]