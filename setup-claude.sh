#!/bin/bash
#
# Description
#   Setup of Claude Code and Codex CLI configuration.
#   Installs marketplace plugins/skills and creates symlinks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CODEX_DIR="$HOME/.codex"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create symbolic link with backup
create_symlink() {
    local source="$1"
    local target="$2"

    if [ -L "$target" ]; then
        log_info "Symlink already exists: $target"
        return 0
    fi

    if [ -e "$target" ]; then
        log_warn "Backing up existing: $target"
        mv "$target" "$target.backup"
    fi

    ln -sf "$source" "$target"
    log_info "Created symlink: $target -> $source"
}

# Setup Claude Code
setup_claude() {
    log_info "Setting up Claude Code..."

    mkdir -p "$CLAUDE_DIR"

    # Symlink configuration files
    create_symlink "$SCRIPT_DIR/dot_claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    create_symlink "$SCRIPT_DIR/dot_claude/settings.json" "$CLAUDE_DIR/settings.json"
    create_symlink "$SCRIPT_DIR/dot_claude/hooks" "$CLAUDE_DIR/hooks"
    create_symlink "$SCRIPT_DIR/dot_claude/commands" "$CLAUDE_DIR/commands"
    create_symlink "$SCRIPT_DIR/dot_claude/rules" "$CLAUDE_DIR/rules"

    # Symlink custom skills (not marketplace skills)
    if [ -d "$SCRIPT_DIR/dot_claude/skills" ]; then
        log_info "Setting up custom skills..."
        mkdir -p "$CLAUDE_DIR/skills"

        for skill_dir in "$SCRIPT_DIR/dot_claude/skills"/*; do
            if [ -d "$skill_dir" ]; then
                skill_name=$(basename "$skill_dir")
                create_symlink "$skill_dir" "$CLAUDE_DIR/skills/$skill_name"
            fi
        done
    fi

    # Install marketplace plugins
    if [ -f "$SCRIPT_DIR/dot_claude/marketplace-plugins.txt" ]; then
        log_info "Installing Claude Code plugins..."
        while IFS= read -r plugin || [ -n "$plugin" ]; do
            # Skip comments and empty lines
            [[ "$plugin" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$plugin" ]] && continue

            log_info "Installing plugin: $plugin"
            claude plugin install "$plugin" || log_warn "Failed to install: $plugin"
        done < "$SCRIPT_DIR/dot_claude/marketplace-plugins.txt"
    fi

    # Install marketplace skills (separate from custom skills)
    if [ -f "$SCRIPT_DIR/dot_claude/marketplace-skills.txt" ]; then
        log_info "Installing marketplace skills..."
        while IFS= read -r skill || [ -n "$skill" ]; do
            # Skip comments and empty lines
            [[ "$skill" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$skill" ]] && continue

            log_info "Installing marketplace skill: $skill"
            claude skill install "$skill" || log_warn "Failed to install: $skill"
        done < "$SCRIPT_DIR/dot_claude/marketplace-skills.txt"
    fi

    log_info "Claude Code setup complete!"
}

# Setup Codex CLI
setup_codex() {
    log_info "Setting up Codex CLI..."

    mkdir -p "$CODEX_DIR"

    # Symlink AGENTS.md and skills
    create_symlink "$SCRIPT_DIR/dot_codex/AGENTS.md" "$CODEX_DIR/AGENTS.md"
    create_symlink "$SCRIPT_DIR/dot_codex/skills" "$CODEX_DIR/skills"
    create_symlink "$SCRIPT_DIR/dot_codex/rules" "$CODEX_DIR/rules"

    # Setup config.toml
    if [ ! -f "$CODEX_DIR/config.toml" ]; then
        log_info "Creating config.toml from common template..."
        cp "$SCRIPT_DIR/dot_codex/config.common.toml" "$CODEX_DIR/config.toml"

        log_warn "Please edit $CODEX_DIR/config.toml to add machine-specific [projects] settings"
    else
        log_info "config.toml already exists, skipping..."
        log_warn "Consider merging settings from: $SCRIPT_DIR/dot_codex/config.common.toml"
    fi

    # Create config.local.toml template if it doesn't exist
    if [ ! -f "$CODEX_DIR/config.local.toml" ]; then
        cat > "$CODEX_DIR/config.local.toml" <<'EOF'
# Machine-specific Codex configuration
# This file is .gitignored and should contain environment-specific settings

# Example: Add trusted projects for this machine
# [projects."/path/to/your/project"]
# trust_level = "trusted"
EOF
        log_info "Created config.local.toml template"
    fi

    log_info "Codex CLI setup complete!"
}

# Main execution
main() {
    log_info "Starting Claude Code and Codex CLI setup..."

    # Check if Claude Code is installed
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code CLI not found. Please install it first."
        exit 1
    fi

    # Check if Codex CLI is installed
    if ! command -v codex &> /dev/null; then
        log_warn "Codex CLI not found. Skipping Codex setup."
        SKIP_CODEX=true
    else
        SKIP_CODEX=false
    fi

    setup_claude

    if [ "$SKIP_CODEX" = false ]; then
        setup_codex
    fi

    log_info ""
    log_info "✨ Setup complete! ✨"
    log_info ""
    log_info "Next steps:"
    log_info "1. Review and update $CODEX_DIR/config.toml with your trusted projects"
    log_info "2. Restart your terminal or run: source ~/.zshrc"
    log_info "3. Verify plugins: claude plugin list"
    log_info "4. Verify skills: claude skill list"
}

main "$@"
