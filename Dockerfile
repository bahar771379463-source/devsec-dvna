FROM node:20-bullseye

WORKDIR /app

COPY package*.json ./

RUN apt-get update && apt-get install -y python3 make g++ \
    && npm install -g npm@latest \
    && npm install

COPY . .

EXPOSE 9090
CMD ["npm", "start"]