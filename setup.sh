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
    if [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; then
        return
    fi

    # Backup existing file, directory, or symlink
    if [ -e "$2" ] || [ -L "$2" ]; then
        if [ -e "$2.backup" ] || [ -L "$2.backup" ]; then
            echo "Backup already exists: $2.backup" >&2
            return 1
        fi
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
backup_and_alias "$PWD/.zshenv" ~/.zshenv
backup_and_alias "$PWD/.zprofile" ~/.zprofile
backup_and_alias "$PWD/.zshrc" ~/.zshrc
backup_and_alias "$PWD/.vimrc" ~/.vimrc

backup_and_alias "$PWD/.config/zsh" ~/.config/zsh
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
    # 以降の symlink は brew の成否に依存しないため、失敗しても続行して最後に伝える。
    # brew bundle は上流から消えた 1 件でも非ゼロで終わるので、
    # ここで即座に中断すると editor 設定の symlink が丸ごと飛ぶ。
    brew_status=0
    bash brew.sh || brew_status=$?

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

    # SuperWhisper: vocabulary / replacements only.
    # New installs default to ~/superwhisper; older installs use ~/Documents/superwhisper.
    # Link into whichever data dirs already exist (do not create empty trees).
    for SUPERWHISPER_DIR in "$HOME/superwhisper" "$HOME/Documents/superwhisper"; do
        if [ -d "$SUPERWHISPER_DIR" ]; then
            mkdir -p "$SUPERWHISPER_DIR/settings"
            backup_and_alias "$PWD/superwhisper/settings.json" "$SUPERWHISPER_DIR/settings/settings.json"
        fi
    done

    if [ "$brew_status" -ne 0 ]; then
        echo "brew.sh failed (exit $brew_status). symlinks are done; see the output above for the packages that were not installed." >&2
        exit "$brew_status"
    fi
fi

echo "finished setup environmtent."
