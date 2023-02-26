#!/bin/bash
#
# Description
#   Setup of my dotfiles.
#   Now, only MacOS with zsh is supported. 
set -euo pipefail

if [ "$(basename $PWD)" != "dotfiles" ]; then
    echo "You should execute this scripts in the current directory."
    echo "Please move to the top of dotfiles repository."
fi

# When creating symbolic links, relative paths are not allowed.
# Pay attention to the execution location.
ln -s "$PWD/.gitconfig" ~/.gitconfig
ln -s "$PWD/.git-templates" ~/.git-templates
ln -s "$PWD/.zshrc" ~/.zshrc
ln -s "$PWD/.vimrc" ~/.vimrc
ln -s "$PWD/.shell_aliases" ~/.shell_aliases

if [[ $(uname) == "Linux" ]]; then
    echo "Linux"
    # TODO: Do something
elif [[ $(uname) == "Darwin" ]]; then
    echo "MacOS"
    bash brew.sh
fi

# Install oh-my-zsh
# https://ohmyz.sh/#install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
