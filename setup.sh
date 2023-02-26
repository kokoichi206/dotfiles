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

# Install with brew
brew install fzf

# Install oh-my-zsh
# https://ohmyz.sh/#install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
