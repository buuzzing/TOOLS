#!/bin/bash
# prepare environment for wecross demo

LOG_INFO() {
    echo -e "\033[36mINFO: $@\033[0m"
}

LOG_WARN() {
    echo -e "\033[33mWARNING: $@\033[0m"
}

LOG_ERROR() {
    echo -e "\033[31mERROR: $@\033[0m" >&2
}

# check architecture
arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
    LOG_ERROR "unsupported architecture: $arch, expect: x86_64"
    exit 1
fi

# check system
release=$(cat /etc/os-release | grep -E '^ID=.*' | awk -F'=' '{print $2}')
if [ "$release" != "ubuntu" -a "$release" != "debian" -a "$release" != "arch" ]; then
    LOG_ERROR "unsupported system: $release"
    exit 1
fi

# $1: command, $2: package name for ubuntu/debian, $3: package name for arch
check_and_install() {
    if ! type $1 >/dev/null 2>&1; then
        LOG_WARN "$1 not found"

        LOG_INFO "installing $1..."
        case $release in
        ubuntu | debian)
            sudo apt install $2
            ;;
        arch)
            sudo pacman -Sy $3
            ;;
        esac

        # check if $1 installation was successful
        if ! type $1 >/dev/null 2>&1; then
            LOG_ERROR "$1 installation failed"
            exit 1
        fi
        LOG_INFO "$1 installation successful"
    fi
}

# check wget
check_and_install wget wget wget

# check git
check_and_install git git git

# check go
GO_URL="https://golang.google.cn/dl/go1.18.linux-amd64.tar.gz"
GO_FILE="go1.18.linux-amd64.tar.gz"
if ! type go >/dev/null 2>&1; then
    LOG_WARN "go not found"

    LOG_INFO "downloading go..."
    wget -P /tmp $GO_URL

    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go1.18.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >>$HOME/.bashrc
    source $HOME/.bashrc

    # check if go installation was successful
    if ! type go >/dev/null 2>&1; then
        echo "go installation failed"
        exit 1
    fi
    LOG_INFO "go installation successful"

    # set go proxy
    go env -w GO111MODULE=on
    go env -w GOPROXY=https://goproxy.cn,direct
fi

# check openssl
check_and_install openssl libssl-dev openssl

# check curl
check_and_install curl curl curl

# check expect
check_and_install expect expect expect

# check tree
check_and_install tree tree tree

# check fontconfig
check_and_install fc-list fontconfig fontconfig

# check lsof
check_and_install lsof lsof lsof

# check java
check_and_install java openjdk-11-jdk jdk11-openjdk

# check mysql
check_and_install mysql mysql-server mariadb

# check docker
check_and_install docker docker.io docker

# check docker-compose
check_and_install docker-compose docker-compose docker-compose

# check docker permission
user=$(whoami)
if ! groups | grep -q docker; then
    echo "warning: docker permission denied" >&2

    sudo usermod -aG docker $user
    newgrp docker

    # check if docker permission was successful
    if ! groups | grep -q docker; then
        echo "docker permission failed"
        exit 1
    fi
    echo "docker permission successful"
fi

LOG_INFO "environment preparation successful"