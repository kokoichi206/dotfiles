#!/bin/bash
set -e

DOTFILES_REPO="$HOME/dotfiles"

if [ ! -e "$DOTFILES_REPO" ]; then
    echo "dotfiles repository is not found."
    git clone https://github.com/kokoichi206/dotfiles.git "$DOTFILES_REPO"
fi

cd "$DOTFILES_REPO"
# maybe: create synbolic link for all files in the repository.
