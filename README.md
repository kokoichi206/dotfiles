# dotfiles

Personal dotfiles for macOS (zsh).

## Setup

```sh
# Clone (kept under ghq)
git clone https://github.com/kokoichi206/dotfiles.git \
  ~/ghq/github.com/kokoichi206/dotfiles
cd ~/ghq/github.com/kokoichi206/dotfiles

# Symlink configs, install Homebrew packages, install oh-my-zsh
bash setup.sh
```

`setup.sh` symlinks the configs (wezterm, mise, neovim, git, zsh, lazygit, VSCode/Windsurf, …)
and runs `brew.sh` to install everything from the `Brewfile`.

## nix-darwin + home-manager

nix-darwin manages macOS system defaults (Dock, trackpad, keyboard shortcuts) and
home-manager manages user CLI tools. Both are applied together via `make nix-switch`.

```sh
# Create local identity file (username / hostname / system; not tracked by Git)
cp nix/local/identity.example.nix nix/local/identity.nix

# First machine only: darwin-rebuild is not yet on PATH
make nix-bootstrap

make nix-switch   # Apply configuration
make nix-build    # Build without applying (dry-run)
make nix-check    # Validate flake outputs
make nix-update   # Update pinned inputs (flake.lock)
```

If the hostname differs from `hostname -s`:

```sh
DARWIN_HOST=<hostname> make nix-switch
```

## What manages what

| Layer | Manages | Source |
| --- | --- | --- |
| mise | language runtimes — node, python, ruby, rust, terraform, neovim, … | `.config/mise/config.toml` |
| home-manager | CLI tools — bat, eza, fd, ripgrep, gh, ghq, starship, … | `nix/home/identity.nix` |
| nix-darwin | macOS system defaults | `nix/darwin/configuration.nix` |
| Homebrew | GUI apps & docker | `Brewfile` |

## Maintenance

```sh
make help              # list all make targets
make update-brewfile   # regenerate Brewfile from installed packages
```
