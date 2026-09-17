.DEFAULT_GOAL := help
FLAKE_REF := path:.
DARWIN_HOST ?= $(shell hostname -s)

.PHONY: help
help:	## https://postd.cc/auto-documented-makefile/
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# Home Manager が所有する CLI ツールの、Brewfile 側での名前。
# 実体の定義は nix/home/identity.nix の home.packages で、名前が異なるものを含む
# (delta -> git-delta, tealdeer -> tlrc)。追加時は両方を揃えること。
# brew-diff はこれらを「宣言に足すのではなく brew から消すもの」として印を付ける。
HOME_MANAGER_PACKAGES := bat eza fd ripgrep jq fzf zoxide gh ghq tree watch starship git-delta tlrc rainfrog

# Brewfile は「入れたいものの宣言」であり、brew bundle dump が出す
# 「いま入っているもののスナップショット」とは別の文書。dump で上書きすると
# (1) その機械に入っていない宣言が消え (2) アドホックに入れたものが宣言へ昇格し
# (3) 列挙に失敗した種別が丸ごと落ちる。差分を見て手で宣言を直す。
#
# brew bundle cleanup は --force を付けない限り一覧するだけで削除しない。
# ここに --force を足さないこと。
.PHONY: brew-diff
brew-diff:	## Brewfile の宣言と実際の導入状況の差分を表示 (変更はしない)
	@echo "== 宣言しているのに入っていない =="
	@brew bundle check --verbose --file=Brewfile 2>/dev/null | grep -E '^→' || echo "  なし"
	@echo
	@echo "== 入っているのに宣言していない =="
	@pattern="$$(echo '$(HOME_MANAGER_PACKAGES)' | tr ' ' '|')"; \
		brew bundle cleanup --file=Brewfile 2>/dev/null \
		| sed -n '/^Would uninstall/,$$p' \
		| sed '/^Would `brew cleanup`/,$$d' \
		| sed -E "s/^($$pattern)\$$/\1    <- Home Manager が所有。宣言せず brew から消す/" \
		| grep . || echo "  なし"

# settings.json は Claude Code 自身が rename 書き込みで symlink を壊すため、
# symlink ではなくコピーで管理し、repo <-> ~/.claude を双方向に同期する。
# jq -S を経由させることで (1)キー順を CC の出力に合わせて正規化し diff を最小化し
# (2)不正な JSON を書き込む前に弾く。
DOT_CLAUDE_SETTINGS  := dot_claude/settings.json
LIVE_CLAUDE_SETTINGS := $(HOME)/.claude/settings.json

# live 側で未配線の hook は pull で repo からも消えるため、pull 直後に配線を検査する。
# lint が落ちたら repo の配線を復元してから commit すること。
.PHONY: claude-pull
claude-pull:	## ~/.claude/settings.json の変更を repo に取り込む (要 git diff レビュー)
	jq -S . "$(LIVE_CLAUDE_SETTINGS)" | ./claude-normalize-home.sh | jq -S . > "$(DOT_CLAUDE_SETTINGS)"
	@./claude-lint-settings.sh || { echo "hook wiring was dropped by pull. restore it in $(DOT_CLAUDE_SETTINGS) before committing."; exit 1; }
	@echo "pulled live -> repo (\$$HOME normalized). review: git diff -- $(DOT_CLAUDE_SETTINGS)"

.PHONY: claude-apply
claude-apply:	## repo の settings.json と skills/agents symlink を ~/.claude へ反映 (要 claude 再起動)
	./claude-lint-settings.sh
	jq -S . "$(DOT_CLAUDE_SETTINGS)" > "$(LIVE_CLAUDE_SETTINGS)"
	./setup-claude.sh link
	@echo "applied repo -> live. restart claude to take effect."

.PHONY: test-claude-hooks
test-claude-hooks:	## dot_claude/hooks の単体テストを実行
	python3 dot_claude/hooks/inject-rules-on-write.test.py

.PHONY: claude-lint
claude-lint:	## settings.json の hook 配線を検査
	./claude-lint-settings.sh

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

# nix-darwin を使わず、ユーザー環境だけを適用する経路。sudo を必要としない。
# nix-darwin と同一マシンで併用しないこと (パッケージの置き場所が競合する)。
.PHONY: hm-bootstrap
hm-bootstrap:	## [初回] home-manager 単体でユーザー環境を適用 (home-manager コマンド不在時)
	nix --extra-experimental-features 'nix-command flakes' build $(FLAKE_REF)#homeConfigurations.$(DARWIN_HOST).activationPackage
	./result/activate

.PHONY: hm-switch
hm-switch:	## home-manager 単体でユーザー環境を適用 (sudo 不要)
	home-manager switch --flake $(FLAKE_REF)#$(DARWIN_HOST)

.PHONY: hm-build
hm-build:	## home-manager 単体構成をビルドのみ (dry-run)
	nix --extra-experimental-features 'nix-command flakes' build --no-link $(FLAKE_REF)#homeConfigurations.$(DARWIN_HOST).activationPackage
