.DEFAULT_GOAL := help
FLAKE_REF := path:.
DARWIN_HOST ?= $(shell hostname -s)

.PHONY: help
help:	## https://postd.cc/auto-documented-makefile/
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: update-brewfile
update-brewfile:	## Update Brewfile from current brew packages
	@echo "Updating Brewfile..."
	brew bundle dump --force
	@echo "Brewfile updated successfully!"

# settings.json は Claude Code 自身が rename 書き込みで symlink を壊すため、
# symlink ではなくコピーで管理し、repo <-> ~/.claude を双方向に同期する。
# jq -S を経由させることで (1)キー順を CC の出力に合わせて正規化し diff を最小化し
# (2)不正な JSON を書き込む前に弾く。
DOT_CLAUDE_SETTINGS  := dot_claude/settings.json
LIVE_CLAUDE_SETTINGS := $(HOME)/.claude/settings.json

.PHONY: claude-pull
claude-pull:	## ~/.claude/settings.json の変更を repo に取り込む (要 git diff レビュー)
	jq -S . "$(LIVE_CLAUDE_SETTINGS)" | ./claude-normalize-home.sh | jq -S . > "$(DOT_CLAUDE_SETTINGS)"
	@echo "pulled live -> repo (\$$HOME normalized). review: git diff -- $(DOT_CLAUDE_SETTINGS)"

.PHONY: claude-apply
claude-apply:	## repo の settings.json を ~/.claude へ反映 (要 claude 再起動)
	jq -S . "$(DOT_CLAUDE_SETTINGS)" > "$(LIVE_CLAUDE_SETTINGS)"
	@echo "applied repo -> live. restart claude to take effect."

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
