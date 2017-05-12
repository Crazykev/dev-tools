#!/bin/bash

if which yum > /dev/null 2>&1; then
    PM='yum'
else
    echo "only support yum package manager"
    exit 1
fi

if which vim > /dev/null 2>&1; then
    echo "vim already exist, skip install"
else
    echo "Install vim plugins"
    wget -qO- https://raw.github.com/Crazykev/vim/master/setup.sh | bash -x
fi

echo "Install basic dependencies"
$PM update -y && $PM install -y \
    autoconf automake device-mapper-devel libvirt libvirt-devel net-tools

echo "Install hypercontainer package"
curl -sSL https://hypercontainer.io/install | bash

source ~/.bashrc
GOPATH=${GOPATH:-$HOME/go-project}
K8S_ROOT=${K8S_ROOT:-$GOPATH/src/k8s.io/kubernetes}
FRAKTI_ROOT=${FRAKTI_ROOT:-$GOPATH/src/k8s.io/frakti}
HYPERD_ROOT=${HYPERD_ROOT:-$GOPATH/src/github.com/hyperhq/hyperd}
HYPERSTART_ROOT=${HYPERSTART_ROOT:-$GOPATH/src/github.com/hyperhq/hyperstart}
echo "git clone packages"
git clone https://github.com/kubernetes/kubernetes $K8S_ROOT
git clone https://github.com/kubernetes/frakti $FRAKTI_ROOT
git clone https://github.com/hyperhq/hyperd $HYPERD_ROOT
git clone https://github.com/hyperhq/hyperstart $HYPERSTART_ROOT

echo "setup hyperd env"
cat >> /etc/libvirt/qemu.conf <<EOF
user = "root"
group = "root"
clear_emulator_capabilities = 0
EOF
systemctl restart libvirt
cd $HYPERD_ROOT
./autogen.sh && ./configure && make
cp hyperd hyperctl /usr/bin/
cat >/etc/hyper/config <<EOF
# Boot kernel
Kernel=/var/lib/hyper/kernel
# Boot initrd
Initrd=/var/lib/hyper/hyper-initrd.img
# Storage driver for hyperd, valid value includes devicemapper, overlay, and aufs
StorageDriver=overlay
# Hypervisor to run containers and pods, valid values are: libvirt, qemu, kvm, xen
Hypervisor=libvirt
# The tcp endpoint of gRPC API
gRPCHost=127.0.0.1:22318
EOF
systemctl enable hyperd
systemctl restart hyperd

echo "setup cni"
go get -u -d github.com/containernetworking/cni
cd $GOPATH/src/github.com/containernetworking/cni
mkdir -p /etc/cni/net.d
sh -c 'cat >/etc/cni/net.d/10-mynet.conf <<-EOF
{
    "cniVersion": "0.3.0",
    "name": "mynet",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "subnet": "10.10.0.0/16",
        "routes": [
            { "dst": "0.0.0.0/0"  }
        ]
    }
}
EOF'
sh -c 'cat >/etc/cni/net.d/99-loopback.conf <<-EOF
{
    "cniVersion": "0.3.0",
    "type": "loopback"
}
EOF'
./build
sudo mkdir -p /opt/cni/bin
sudo cp bin/* /opt/cni/bin/

echo "setup frakti env"
cd $FRAKTI_ROOT
make
cp out/frakti /usr/bin/
cat <<EOF > /lib/systemd/system/frakti.service
[Unit]
Description=Hypervisor-based container runtime for Kubernetes
Documentation=https://github.com/kubernetes/frakti
After=network.target

[Service]
ExecStart=/usr/bin/frakti --v=3 \
          --log-dir=/var/log/frakti \
          --logtostderr=false \
          --listen=/var/run/frakti.sock \
          --streaming-server-addr=%H \
          --hyper-endpoint=127.0.0.1:22318
MountFlags=shared
TasksMax=8192
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable frakti
systemctl start frakti

echo "install docker"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64-unstable
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
setenforce 0
yum install -y kubernetes-cni docker
sed -i 's/native.cgroupdriver=systemd/native.cgroupdriver=cgroupfs/g' /usr/lib/systemd/system/docker.service
systemctl enable docker
systemctl start docker
