FROM node:16-bullseye

WORKDIR /app

COPY package*.json ./

RUN apt-get update && apt-get install -y python3 make g++

# إصلاح مشاكل npm المحتملة
RUN npm config set fetch-timeout 600000 \
    && npm config set fetch-retries 5 \
    && npm config set registry https://registry.npmmirror.com

# تثبيت bcrypt منفردًا (يتجنب فشل البناء)
RUN npm install bcrypt@5.0.1

# تثبيت باقي الاعتمادات
RUN npm install

COPY . .

RUN chmod +x /app/entrypoint.sh || true

EXPOSE 9090

CMD ["npm", "start"]