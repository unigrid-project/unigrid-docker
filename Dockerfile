# Build command
# docker build --no-cache . --tag=unigrid/unigrid:beta
# commit a new image
# sudo docker commit [CONTAINER_ID] [new_image_name]
# sudo docker commit 852f2b256e44 unigrid/unigrid:edits
# mount the volume to the image
# docker run -it --name=blah_blah_blah --mount source=unigrid_data,destination=/root/.unigrid unigrid/unigrid:beta
# docker run -it --name=server-test --mount source=data-volume,destination=/root/.unigrid unigrid/unigrid:beta
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
ADD https://raw.githubusercontent.com/unigrid-project/unigrid-installer/main/service.sh /usr/local/bin/ugd_service
RUN chmod +x /usr/local/bin/ugd_service
ADD https://raw.githubusercontent.com/unigrid-project/unigrid-installer/main/unigrid.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/unigrid.sh
RUN unigrid.sh root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["cron","-f", "-l", "2"]
RUN apt-get update -y
RUN apt-get upgrade -y