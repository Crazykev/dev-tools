FROM centos:latest

MAINTAINER "Crazykev <crazykev@zju.edu.cn>"

ENV NL_VERSION="3.2.29" \
    POPT_VERSION="1.16" \
    IPVSADM_REPO="https://github.com/Crazykev/ipvsadm" \
    OUTPUT_DIR="/data/"

RUN yum clean all && \
    yum install -y --nogpgcheck \
        binutils \
        bison \
        flex \
        gcc \
        git \
        make \
        tar \
        vim \
        wget

ADD build.sh /root/

WORKDIR /root/

CMD ["./build.sh"]
