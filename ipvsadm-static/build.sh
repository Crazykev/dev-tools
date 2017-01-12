#!/bin/bash

# This is a script to build and strip ipvsadm binary, 
# which use libnl/libpopt as static lib, others like
# libm/glibc/pthread will use dynamic lib.

set -o errexit
set -o nounset
set -o pipefail

NL_VERSION=${NL_VERSION:-"3.2.29"}
POPT_VERSION=${POPT_VERSION:-"1.16"}
IPVSADM_REPO=${IPVSADM_REPO:-"https://github.com/Crazykev/ipvsadm"}
OUTPUT_DIR=${OUTPUT_DIR:-/data}
PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}

# add '/usr/lib/pkgconfig/' in case it is not in PKG_CONFIG_PATH
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/lib/pkgconfig

# build static libnl and libpopt
cd /tmp/
# download and build libnl
wget https://github.com/thom311/libnl/releases/download/libnl${NL_VERSION//\./_}/libnl-${NL_VERSION}.tar.gz
tar -xvf libnl-${NL_VERSION}.tar.gz
cd libnl-${NL_VERSION}
./configure --prefix=/usr     \
            --sysconfdir=/etc 
make && make install

cd /tmp/
# download and build popt
wget http://rpm5.org/files/popt/popt-${POPT_VERSION}.tar.gz
tar -xvf popt-${POPT_VERSION}.tar.gz
cd popt-${POPT_VERSION}
./configure --prefix=/usr
make && make install

# build ipvsadm
cd /tmp/
git clone ${IPVSADM_REPO} ipvsadm
cd ipvsadm
make

# strip ipvsadm binary
mkdir -p ${OUTPUT_DIR}
strip ./ipvsadm -o ${OUTPUT_DIR}/ipvsadm
