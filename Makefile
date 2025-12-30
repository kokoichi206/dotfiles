.DEFAULT_GOAL := help

.PHONY: help
help:	## https://postd.cc/auto-documented-makefile/
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: update-brewfile
update-brewfile:
	@echo "Updating Brewfile..."
	brew bundle dump --force
	@echo "Brewfile updated successfully!"
