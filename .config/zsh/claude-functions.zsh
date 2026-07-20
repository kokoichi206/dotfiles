claude-skill-try() {
  local skill_name="$1"
  if [ -z "$skill_name" ]; then
    echo "Usage: claude-skill-try <skill-name>"
    echo "  Creates a temporary skill in ~/.claude/skills/ for testing"
    echo "  Use 'claude-skill-promote' to move it to dotfiles when ready"
    return 1
  fi

  local skill_dir="$HOME/.claude/skills/$skill_name"
  if [ -d "$skill_dir" ]; then
    echo "Skill already exists: $skill_dir"
    ${EDITOR:-vim} "$skill_dir/SKILL.md"
    return 0
  fi

  mkdir -p "$skill_dir"
  cat > "$skill_dir/SKILL.md" <<EOF
---
name: $skill_name
description:
---

# $skill_name

## 概要

## 主要原則

## チェックリスト

- [ ]
EOF

  echo "Created temporary skill: $skill_dir/SKILL.md"
  echo "Try it out, then run 'claude-skill-promote $skill_name' to add to dotfiles"
  ${EDITOR:-vim} "$skill_dir/SKILL.md"
}

claude-skill-promote() {
  local skill_name="$1"
  if [ -z "$skill_name" ]; then
    echo "Usage: claude-skill-promote <skill-name>"
    echo "  Moves skill from ~/.claude/skills/ to dotfiles and creates symlink"
    return 1
  fi

  local temp_skill="$HOME/.claude/skills/$skill_name"
  local dotfiles_skill="$DOTFILES_DIR/dot_claude/skills/$skill_name"

  if [ ! -d "$temp_skill" ]; then
    echo "Error: Skill not found in ~/.claude/skills/$skill_name"
    echo "Use 'claude-skill-try $skill_name' to create it first"
    return 1
  fi

  if [ -L "$temp_skill" ]; then
    echo "Skill is already promoted (symlink detected)"
    echo "Location: $(readlink $temp_skill)"
    return 0
  fi

  if [ -d "$dotfiles_skill" ]; then
    echo "Error: Skill already exists in dotfiles: $dotfiles_skill"
    return 1
  fi

  echo "Moving skill to dotfiles..."
  mv "$temp_skill" "$dotfiles_skill"

  ln -sf "$dotfiles_skill" "$temp_skill"

  echo "Skill promoted to dotfiles"
  echo "  Dotfiles location: $dotfiles_skill"
  echo "  Symlink created: $temp_skill -> $dotfiles_skill"
  echo ""
  echo "Next steps:"
  echo "  cd $DOTFILES_DIR"
  echo "  git add dot_claude/skills/$skill_name"
  echo "  git commit -m 'Add $skill_name skill'"
}

claude-skill-list() {
  echo "=== Claude Code Custom Skills ==="
  if [ -d "$DOTFILES_DIR/dot_claude/skills" ]; then
    ls -1 "$DOTFILES_DIR/dot_claude/skills"
  else
    echo "No custom skills found"
  fi

  echo ""
  echo "=== Marketplace Skills ==="
  if [ -f "$DOTFILES_DIR/dot_claude/marketplace-skills.txt" ]; then
    grep -v "^#" "$DOTFILES_DIR/dot_claude/marketplace-skills.txt" | grep -v "^$"
  else
    echo "No marketplace skills configured"
  fi
}
