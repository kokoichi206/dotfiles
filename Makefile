.DEFAULT_GOAL := help

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
