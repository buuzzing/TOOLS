#!/bin/bash
# install zsh and oh-my-zsh
# install plugins: zsh-autosuggestions, zsh-syntax-highlighting

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

# check zsh
check_and_install zsh zsh zsh

# check and install oh-my-zsh
if [ ! -d $HOME/.oh-my-zsh ]; then
    echo "installing oh-my-zsh..."
    echo "after installation, type 'exit' or Ctrl-D to exit zsh and return to continue the script"
    # sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sh -c "$(wget -O- https://install.ohmyz.sh/)"
fi

# check oh-my-zsh installation
if [ ! -d $HOME/.oh-my-zsh/custom/plugins/example ]; then
    echo "oh-my-zsh installation failed"
    exit 1
fi

# check zsh-autosuggestions
if [ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
    echo "installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    echo "zsh-autosuggestions has been cloned to $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi

# check zsh-syntax-highlighting
if [ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
    echo "installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    echo "zsh-syntax-highlighting has been cloned to $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
fi

# check if zsh-autosuggestions and zsh-syntax-highlighting have been enabled
if ! grep -q 'zsh-autosuggestions' $HOME/.zshrc; then
    echo "enable zsh-autosuggestions and zsh-syntax-highlighting"
    sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' $HOME/.zshrc
fi
