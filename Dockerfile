FROM ubuntu:latest as builder
LABEL org.unigrid.image.authors="UGD Software AB"
LABEL version="0.0.3"
LABEL description="Unigrid docker image."
RUN apt-get update && \
    mkdir -p /etc/ssl/certs/java && \
    /usr/bin/printf '\xfe\xed\xfe\xed\x00\x00\x00\x02\x00\x00\x00\x00\xe2\x68\x6e\x45\xfb\x43\xdf\xa4\xd9\x92\xdd\x41\xce\xb6\xb2\x1c\x63\x30\xd7\x92' > /etc/ssl/certs/java/cacerts && \
    chmod 644 /etc/ssl/certs/java/cacerts && \
    apt-get install -y ca-certificates-java

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
# build testnet docker image
#RUN unigrid.sh root testnet
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
# build testnet docker image
#ENTRYPOINT ["/entrypoint.sh", "testnet"]
RUN /usr/local/bin/hedgehog.bin --force-unpack
RUN ln -s /root/.unigrid/local /root/.local
CMD ["cron","-f", "-l", "2"]
RUN apt-get update -y
RUN apt-get upgrade -y