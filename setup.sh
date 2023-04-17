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


# from $2 to $1
backup_and_alias() {
    if [ -f "$2" ]; then
        mv "$2" "$2.backup"
    fi
    # When creating symbolic links, relative paths are not allowed.
    # Pay attention to the execution location.
    ln -s "$1" "$2"
}

backup_and_alias "$PWD/.gitconfig" ~/.gitconfig
backup_and_alias "$PWD/.git-templates" ~/.git-templates
backup_and_alias "$PWD/.zshrc" ~/.zshrc
backup_and_alias "$PWD/.vimrc" ~/.vimrc
backup_and_alias "$PWD/.shell_aliases" ~/.shell_aliases

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

echo "finished setup environmtent."
