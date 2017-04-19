#!/bin/bash

function preinstall() {
    if which apt-get > /dev/null; then
        apt-get update && apt-get install -y apt-transport-https
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
        cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
        apt-get update -y
        apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni
    elif which yum > /dev/null; then
        PM="yum"
        cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
        yum install -y docker kubelet kubeadm kubectl kubernetes-cni
    else
        echo "apt-get or yum can't find"
        exit 1
    fi

    systemctl enable docker && systemctl start docker
    systemctl enable kubelet && systemctl start kubelet
}

setenforce 0

preinstall
