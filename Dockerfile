# Damn Vulnerable NodeJS Application

FROM node:14
LABEL MAINTAINER "Subash SN"

WORKDIR /app

COPY . .

RUN apt-get update && apt-get install -y python3 make g++ && \
    chmod +x /app/entrypoint.sh && npm install

CMD ["bash", "/app/entrypoint.sh"]