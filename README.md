# dotfiles

## other installation

- [go](https://go.dev/doc/install)
- [docker](https://docs.docker.com/engine/install/ubuntu)
- [oh-my-zsh](https://ohmyz.sh/#install)

## brew

``` sh
# Brewfile is created by this command.
brew bundle dump --force
```

## config

``` sh
ln -s "$HOME"/ghq/github.com/kokoichi206/dotfiles/.config/nvim ~/.config/nvim
```

## DOING...

``` sh
curl -o https://github.com/kokoichi206/dotfiles/setup-repo.sh
```

## nix-darwin + home-manager

```sh
# Create local identity file (not tracked by Git)
cp nix/local/identity.example.nix nix/local/identity.nix

# Build system derivation
make nix-build

# Apply configuration
make nix-switch

# Validate flake outputs
make nix-check

# Update pinned inputs
make nix-update
```

If hostname differs from `hostname`, use:

```sh
DARWIN_HOST=<hostname> make nix-switch
```
