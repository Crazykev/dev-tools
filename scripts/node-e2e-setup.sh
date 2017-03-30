#!/bin/bash

if which yum > /dev/null 2>&1; then
    PM='yum'
else
    echo "only support yum package manager"
    exit 1
fi

echo "Install vim plugins"
wget -qO- https://raw.github.com/Crazykev/vim/master/setup.sh | bash -x

echo "Install basic dependencies"
$PM update -y && $PM install -y \
    autoconf automake device-mapper-devel libvirt-devel net-tools

echo "Install hypercontainer package"
$PM install -y https://hypercontainer-install.s3.amazonaws.com/hyper-container-0.8.0-1.el7.centos.x86_64.rpm
$PM install -y https://hypercontainer-install.s3.amazonaws.com/hyperstart-0.8.0-1.el7.centos.x86_64.rpm
$PM install -y https://hypercontainer-install.s3.amazonaws.com/qemu-hyper-2.4.1-3.el7.centos.x86_64.rpm

GOPATH=${GOPATH:-/go-project}
echo "git clone packages"
git clone https://github.com/kubernetes/kubernetes $GOPATH/src/k8s.io/kubernetes
git clone https://github.com/kubernetes/frakti $GOPATH/src/k8s.io/frakti
git clone https://github.com/hyperhq/hyperd $GOPATH/src/github.com/hyperhq/hyperd
git clone https://github.com/hyperhq/hyperstart $GOPATH/src/github.com/hyperhq/hyperstart


