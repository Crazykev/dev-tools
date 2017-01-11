FROM ubuntu:latest

MAINTAINER "Crazykev <crazykev@zju.edu.cn>"

RUN apt-get update -y && \
	apt-get install -y \
    	apt-utils \
        gcc \
    	git \
        lsb-release \
        lsb-core \
        make \
        python-pip \
        vim && \
    pip install --upgrade pip && \
    pip install apt-select && \
    apt-select && \
    cp /etc/apt/sources.list /etc/apt/sources.list.backup && \
	mv sources.list /etc/apt/ && \
	apt-get update -y
    
# Run your app
WORKDIR /root/
CMD bash
