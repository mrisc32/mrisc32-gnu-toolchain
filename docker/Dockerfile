ARG _cpu_arch="amd64"

FROM ${_cpu_arch}/ubuntu:20.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       bison \
       build-essential \
       curl \
       flex \
       texinfo \
    && rm -rf /var/lib/apt/lists/*

