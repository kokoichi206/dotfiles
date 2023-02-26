#!/bin/bash
#
# Description
#   Setup for my dotfiles.
set -euo pipefail

if [ "$(basename $PWD)" != "dotfiles" ]; then
    echo "You should execute this scripts in the current directory."
    echo "Please move to the top of dotfiles repository."
fi

# When creating symbolic links, relative paths are not allowed.
# Pay attention to the execution location.
ln -s "$PWD/.gitconfig" ~/.gitconfig
ln -s "$PWD/.git-templates" ~/.git-templates
