FROM ubuntu:20.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       bison \
       build-essential \
       curl \
       flex \
       texinfo \
       zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

