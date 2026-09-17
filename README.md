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

`setup.sh` symlinks the configs (wezterm, mise, neovim, git, zsh, lazygit, VSCode/Windsurf, SuperWhisper vocabulary, …)
and runs `brew.sh` to install everything from the `Brewfile`.

SuperWhisper details: [`superwhisper/README.md`](./superwhisper/README.md).

## nix-darwin + home-manager

home-manager owns user CLI tools **and** user-scope macOS defaults (Dock, trackpad,
keyboard shortcuts, screenshot location). nix-darwin owns only what needs root:
`/etc`, launchd daemons, `pmset`, and `/Library/Preferences`.

Two application paths. **Pick one per machine** — mixing them puts packages in two
different profiles (`/etc/profiles/per-user` vs `~/.nix-profile`).

```sh
# Create local identity file (username / hostname / system; not tracked by Git)
cp nix/local/identity.example.nix nix/local/identity.nix
```

**Path 1 — nix-darwin + home-manager (needs sudo on every switch)**

```sh
make nix-bootstrap   # First machine only: darwin-rebuild is not yet on PATH
make nix-switch      # Apply configuration
make nix-build       # Build without applying (dry-run)
make nix-check       # Validate flake outputs
make nix-update      # Update pinned inputs (flake.lock)
```

**Path 2 — home-manager standalone (no sudo after Nix itself is installed)**

Use this where typing a sudo password on every switch is painful (remote machines),
or where the root-scope settings are overridden anyway (MDM-managed machines).

```sh
make hm-bootstrap   # First time: the home-manager command is not yet on PATH
make hm-switch      # Apply user environment
make hm-build       # Build without applying (dry-run)
```

Both paths key their flake output by hostname. If it differs from `hostname -s`:

```sh
DARWIN_HOST=<hostname> make nix-switch   # or make hm-switch
```

## What manages what

| Layer | Manages | Source |
| --- | --- | --- |
| mise | language runtimes — node, python, ruby, rust, terraform, neovim, … | `.config/mise/config.toml` |
| home-manager | CLI tools — bat, eza, fd, ripgrep, gh, ghq, starship, … | `nix/home/identity.nix` |
| home-manager | user-scope macOS defaults — Dock, trackpad, shortcuts, … | `nix/home/darwin-defaults.nix` |
| nix-darwin | root-scope system settings — `/etc`, launchd, `pmset`, login window | `nix/darwin/configuration.nix` |
| Homebrew | GUI apps, docker, and tools installed via `brew` / `cargo` / `go` / `npm` entries | `Brewfile` |

CLI tools live in exactly one layer. A package that home-manager owns must not appear in
the `Brewfile` under any entry type — `brew`, `cargo`, `go` and `npm` all install binaries
onto `PATH`. `make update-brewfile` strips the `HOME_MANAGER_PACKAGES` list across those
entry types after `brew bundle dump`, so a package cannot creep back in as a dependency.

## Maintenance

```sh
make help              # list all make targets
make update-brewfile   # regenerate Brewfile from installed packages
```
