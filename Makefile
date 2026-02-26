.DEFAULT_GOAL := help
FLAKE_REF := path:.
DARWIN_HOST ?= $(shell hostname)

.PHONY: help
help:	## https://postd.cc/auto-documented-makefile/
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: update-brewfile
update-brewfile:	## Update Brewfile from current brew packages
	@echo "Updating Brewfile..."
	brew bundle dump --force
	@echo "Brewfile updated successfully!"

.PHONY: update-claude-settings
update-claude-settings:	## Update .claude settings from ~/.claude
	@echo "Updating Claude Code settings..."
	@mkdir -p .claude/commands
	@cp ~/.claude/CLAUDE.md .claude/
	@cp ~/.claude/settings.json .claude/
	@cp ~/.claude/commands/pr.md .claude/commands/
	@echo "Claude Code settings updated successfully!"

.PHONY: nix-check
nix-check:	## Check flake outputs
	nix --extra-experimental-features 'nix-command flakes' flake check $(FLAKE_REF)

# 初回セットアップ用: darwin-rebuild がまだ PATH にない場合に使う
.PHONY: nix-bootstrap
nix-bootstrap:	## [初回] Build and apply nix-darwin configuration
	nix --extra-experimental-features 'nix-command flakes' build $(FLAKE_REF)#darwinConfigurations.$(DARWIN_HOST).system
	sudo ./result/sw/bin/darwin-rebuild switch --flake $(FLAKE_REF)#$(DARWIN_HOST)

.PHONY: nix-switch
nix-switch:	## Apply nix-darwin configuration for this host
	sudo darwin-rebuild switch --flake $(FLAKE_REF)#$(DARWIN_HOST)

.PHONY: nix-build
nix-build:	## Build without applying (dry-run)
	darwin-rebuild build --flake $(FLAKE_REF)#$(DARWIN_HOST)

.PHONY: nix-update
nix-update:	## Update flake.lock inputs
	nix --extra-experimental-features 'nix-command flakes' flake update
