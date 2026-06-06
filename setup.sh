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
    # Backup existing file, directory, or symlink
    if [ -e "$2" ] || [ -L "$2" ]; then
        mv "$2" "$2.backup"
    fi
    # When creating symbolic links, relative paths are not allowed.
    # Pay attention to the execution location.
    ln -s "$1" "$2"
}

backup_and_alias "$PWD/.config/wezterm" ~/.config/wezterm
backup_and_alias "$PWD/.config/mise" ~/.config/mise
backup_and_alias "$PWD/.config/nvim" ~/.config/nvim

backup_and_alias "$PWD/.gitconfig" ~/.gitconfig
backup_and_alias "$PWD/.git-templates" ~/.git-templates
backup_and_alias "$PWD/.zshrc" ~/.zshrc
backup_and_alias "$PWD/.vimrc" ~/.vimrc
backup_and_alias "$PWD/.shell_aliases" ~/.shell_aliases

backup_and_alias "$PWD/.config/zsh-abbr" ~/.config/zsh-abbr
backup_and_alias "$PWD/.config/sheldon" ~/.config/sheldon
backup_and_alias "$PWD/.config/starship.toml" ~/.config/starship.toml

mkdir -p ~/.config/lazygit
backup_and_alias "$PWD/.config/lazygit/config.yml" ~/.config/lazygit/config.yml

# Zed editor: ~/.config/zed は拡張やキャッシュも書き込むため、
# ディレクトリごとではなく設定ファイルだけを個別に symlink する。
mkdir -p ~/.config/zed
backup_and_alias "$PWD/.config/zed/settings.json" ~/.config/zed/settings.json
backup_and_alias "$PWD/.config/zed/keymap.json" ~/.config/zed/keymap.json


if [[ $(uname) == "Linux" ]]; then
    echo "Linux"
    # TODO: Do something
elif [[ $(uname) == "Darwin" ]]; then
    echo "MacOS"
    bash brew.sh

    # VSCode settings
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    if [ -d "$VSCODE_USER_DIR" ]; then
        backup_and_alias "$PWD/.config/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
        backup_and_alias "$PWD/.config/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
        backup_and_alias "$PWD/.config/vscode/snippets" "$VSCODE_USER_DIR/snippets"
    fi

    # Windsurf settings (same config as VSCode)
    WINDSURF_USER_DIR="$HOME/Library/Application Support/Windsurf/User"
    if [ -d "$WINDSURF_USER_DIR" ]; then
        backup_and_alias "$PWD/.config/vscode/settings.json" "$WINDSURF_USER_DIR/settings.json"
        backup_and_alias "$PWD/.config/vscode/keybindings.json" "$WINDSURF_USER_DIR/keybindings.json"
        backup_and_alias "$PWD/.config/vscode/snippets" "$WINDSURF_USER_DIR/snippets"
    fi
fi

# Install oh-my-zsh
# https://ohmyz.sh/#install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "finished setup environmtent."
