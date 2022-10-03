# Build command
# docker build --no-cache . --tag=unigrid/unigrid:beta
# commit a new image
# sudo docker commit [CONTAINER_ID] [new_image_name]
FROM ubuntu:latest as builder
LABEL org.unigrid.image.authors="UGD Software AB"
LABEL version="0.0.1"
LABEL description="Testing Unigrid docker image."
RUN apt-get update
RUN apt-get install -y \
    wget \
    sudo \
    apt-utils \
    bash \
    nano \
    curl \
    gzip \
    unzip \
    xz-utils \
    jq \
    bc \
    cron \
    openjdk-17-jre-headless
ADD https://raw.githubusercontent.com/unigrid-project/unigrid-installer/main/service.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/service.sh
ADD https://raw.githubusercontent.com/unigrid-project/unigrid-installer/main/unigrid.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/unigrid.sh
RUN unigrid.sh root
RUN apt-get update -y
RUN apt-get upgrade -y