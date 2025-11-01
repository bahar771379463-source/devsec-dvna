# Damn Vulnerable NodeJS Application

FROM node:14
LABEL MAINTAINER "Subash SN"

WORKDIR /app

COPY . .

RUN sed -i 's|deb.debian.org/debian|archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i '/security.debian.org/d' /etc/apt/sources.list && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y python3 make g++


RUN apt-get update && apt-get install -y python3 make g++ && \
    chmod +x /app/entrypoint.sh && npm install

CMD ["bash", "/app/entrypoint.sh"]