#!/bin/bash
# prepare environment for chainmaker

GO_URL="https://golang.google.cn/dl/go1.18.linux-amd64.tar.gz"
GO_FILE="go1.18.linux-amd64.tar.gz"

# check architecture
arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
    echo "unsupported architecture: $arch, expect: x86_64" >&2
fi

# check system
release=$(cat /etc/os-release | grep -E '^ID=.*' | awk -F'=' '{print $2}')
if [ "$release" != "ubuntu" -a "$release" != "debian" -a "$release" != "arch" ]; then
    echo "unsupported system: $release" >&2
fi

# $1: command, $2: package name for ubuntu/debian, $3: package name for arch
check_and_install() {
    if ! type $1 >/dev/null 2>&1; then
        echo "warning: $1 not found" >&2

        echo "installing $1..."
        case $release in
        ubuntu | debian)
            sudo apt install $2
            ;;
        arch)
            sudo pacman -S $3
            ;;
        esac

        # check if $1 installation was successful
        if ! type $1 >/dev/null 2>&1; then
            echo "$1 installation failed"
            exit 1
        fi
        echo "$1 installation successful"
    fi
}

# check wget
check_and_install wget wget wget

# check git
check_and_install git git git

# check go
if ! type go >/dev/null 2>&1; then
    echo "warning: go not found" >&2

    echo "downloading go..."
    wget -P /tmp $GO_URL

    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go1.18.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >>$HOME/.profile
    source $HOME/.profile

    # check if go installation was successful
    if ! type go >/dev/null 2>&1; then
        echo "go installation failed"
        exit 1
    fi
    echo "go installation successful"

    # set go proxy
    go env -w GO111MODULE=on
    go env -w GOPROXY=https://goproxy.cn,direct
fi

# check gcc
check_and_install gcc gcc gcc

# check make
check_and_install make make make

# check glibc
glibc_ver=$(ldd --version | head -n 1 | awk -F' ' '{print $NF}' | awk -F'.' '{print $2}')
target="17"
if [ $glibc_ver -lt $target ]; then
    echo "error: glibc version is too low: 2.$glibc_ver, expect: 2.17"
    echo "Ref: https://tutorials.tinkink.net/zh-hans/linux/how-to-update-glibc.html"

    exit 1
fi

# check 7z
check_and_install 7z p7zip-full p7zip

# check tmux
check_and_install tmux tmux tmux

# check docker
check_and_install docker docker.io docker

# check docker permission
if ! groups | grep -q docker; then
    echo "warning: docker permission denied" >&2

    sudo usermod -aG docker $USER
    newgrp docker

    # check if docker permission was successful
    if ! groups | grep -q docker; then
        echo "docker permission failed"
        exit 1
    fi
    echo "docker permission successful"
fi

# check docker-compose
check_and_install docker-compose docker-compose docker-compose