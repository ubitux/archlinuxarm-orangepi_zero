FROM ubuntu:bionic

RUN apt-get update && apt-get install -y \
wget \
make \
gcc \
patch \
python \
python-dev \
swig \
bc \
u-boot-tools \
device-tree-compiler \
gcc-arm-linux-gnueabi && \
rm -rf /var/lib/apt/lists/*

RUN mkdir /app
WORKDIR  /app

CMD ["make"]
