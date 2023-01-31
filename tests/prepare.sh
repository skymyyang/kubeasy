#!/bin/bash
set -x
export KUBE_VERSION=$1

command -v cloud-init >/dev/null 2>&1 && sudo cloud-init status --wait

sudo mkdir -p /home/vagrant/.ssh
sudo cp /vagrant/.ssh/id_rsa /home/vagrant/.ssh/id_rsa
sudo cp /vagrant/.ssh/id_rsa.pub /home/vagrant/.ssh/id_rsa.pub
sudo cp /vagrant/.ssh/id_rsa.pub /home/vagrant/.ssh/authorized_keys
sudo chown -R vagrant:vagrant /home/vagrant/.ssh
sudo chmod 600 /home/vagrant/.ssh/id_rsa /home/vagrant/.ssh/id_rsa.pub

sudo mkdir -p /root/.ssh
sudo cp /vagrant/.ssh/id_rsa /root/.ssh/id_rsa
sudo cp /vagrant/.ssh/id_rsa.pub /root/.ssh/id_rsa.pub
sudo cp /vagrant/.ssh/id_rsa.pub /root/.ssh/authorized_keys
sudo chown -R root:root /root/.ssh
sudo chmod 600 /root/.ssh/id_rsa /root/.ssh/id_rsa.pub

source /etc/os-release
case ${ID} in
centos)
  case ${VERSION_ID} in
  7)
    sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://mirror.centos.org|baseurl=http://mirrors.tuna.tsinghua.edu.cn|g' \
    -i.bak \
    /etc/yum.repos.d/CentOS-*.repo
    ;;
  8)
    sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://mirror.centos.org/$contentdir|baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos|g' \
    -i.bak \
    /etc/yum.repos.d/CentOS-*.repo
    ;;
  esac
  ;;
ubuntu)
  sudo sed -i "s@http://.*archive.ubuntu.com@http://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list
  sudo sed -i "s@http://.*security.ubuntu.com@http://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list
  ;;
debian)
  sudo sed -i "s@https://.*deb.debian.org@http://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list
  sudo sed -i "s@https://.*security.debian.org@http://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list
  ;;
almalinux)
  sed -e 's|^mirrorlist=|#mirrorlist=|g' \
  -e 's|^# baseurl=https://repo.almalinux.org|baseurl=http://mirrors.aliyun.com|g' \
  -i.bak \
  /etc/yum.repos.d/almalinux*.repo
  ;;
rocky)
  sed -e 's|^mirrorlist=|#mirrorlist=|g' \
  -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=http://mirrors.ustc.edu.cn/rocky|g' \
  -i.bak \
  /etc/yum.repos.d/rocky-extras.repo \
  /etc/yum.repos.d/rocky.repo
  ;;
opensuse-leap)
  zypper mr -da
  sudo zypper ar -cfg 'http://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/oss/' tuna-oss
  sudo zypper ar -cfg 'http://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/non-oss/' tuna-non-oss
  sudo zypper ar -cfg 'http://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/oss/' tuna-update
  sudo zypper ar -cfg 'http://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/non-oss/' tuna-update-non-oss
  ;;
arch)
  echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' >/etc/pacman.d/mirrorlist
  pacman -Scc --noconfirm
  pacman -Syy --noconfirm
  pacman -S --noconfirm python3
  ;;
esac

if command -v hostname >/dev/null 2>&1; then
  export cmd='hostname'
elif command -v hostnamectl >/dev/null 2>&1; then
  export cmd='hostnamectl hostname'
fi

if [ $(${cmd}) == 'master01' ]; then
  sudo apt-get clean
  sudo apt-get update
  sudo apt-get install make -y
  sudo git clone -b ${KUBE_VERSION} https://github.com/buxiaomo/kubeasy.git /usr/local/src/kubeasy
  pushd /usr/local/src/kubeasy >/dev/null 2>&1
  set -e
  sudo make runtime
  sudo pip3 install pyOpenSSL --upgrade
  [ -f ./inventory/kubeasy-dev.ini ] || cp ./inventory/template/vagrant-compatibility.template ./inventory/kubeasy-dev.ini
  sudo make prepare
  sudo make deploy REGISTRY_URL=http://192.168.56.11:5000 KUBE_NETWORK=calico
  popd >/dev/null 2>&1
fi
