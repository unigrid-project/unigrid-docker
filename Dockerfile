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
    htop \
    openjdk-17-jre-headless
COPY scripts/service.sh /usr/local/bin/ugd_service
RUN chmod +x /usr/local/bin/ugd_service
COPY scripts/unigrid.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/unigrid.sh
RUN unigrid.sh root
COPY sripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["cron","-f", "-l", "2"]
RUN apt-get update -y
RUN apt-get upgrade -y