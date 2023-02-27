#!/bin/bash

# CAUTION:
# The following command may no longer work depending on the version.
# Please refer to the link of the official documentation for the latest method.


### oh-my-zsh
# https://ohmyz.sh/#install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


### Go
# https://go.dev/dl/
GO_VERSION="go1.20.1"
arch="$(uname -m)"
if [ "${arch}" = "aarch64" ]; then
    # raspberry pi
    arch="arm64"
fi
OS="$(uname | tr '[:upper:]' '[:lower:]')"

TARGET="${GO_VERSION}.${OS}-${arch}.tar.gz"
# rm -rf /usr/local/go && tar -C /usr/local -xzf "go$GO_VERSION.${OS,,}-${arch}.tar.gz"
wget -N "https://golang.org/dl/${TARGET}"
sudo tar -C /usr/local/-xzf "${TARGET}"
rm "${TARGET}"

echo "add the following line to the .bashrc or .zshrc"
echo 'PATH="$HOME/go/bin:/usr/local/go/bin:$PATH"'

### Docker
