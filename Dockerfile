FROM node:-bullseye


WORKDIR /app

COPY package*.json ./
COPY . .

RUN apt-get update && apt-get install -y python3 make g++ \
    && npm uninstall libxmljs \
    && npm install libxmljs2 \
    && npm install \
    && chmod +x /app/entrypoint.sh

EXPOSE 9090


CMD ["npm", "start"]