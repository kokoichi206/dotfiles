codex-skill-try() {
  local skill_name="$1"
  if [ -z "$skill_name" ]; then
    echo "Usage: codex-skill-try <skill-name>"
    echo "  Creates a temporary skill in ~/.codex/skills/ for testing"
    echo "  Use 'codex-skill-promote' to move it to dotfiles when ready"
    return 1
  fi

  if [ -L "$HOME/.codex/skills" ]; then
    echo "Error: ~/.codex/skills is entirely symlinked to dotfiles"
    echo "Create skill directly in dotfiles instead:"
    echo "  mkdir -p $DOTFILES_DIR/dot_codex/skills/$skill_name"
    return 1
  fi

  local skill_dir="$HOME/.codex/skills/$skill_name"
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
  echo "Try it out, then run 'codex-skill-promote $skill_name' to add to dotfiles"
  ${EDITOR:-vim} "$skill_dir/SKILL.md"
}

codex-skill-promote() {
  local skill_name="$1"
  if [ -z "$skill_name" ]; then
    echo "Usage: codex-skill-promote <skill-name>"
    echo "  Moves skill from ~/.codex/skills/ to dotfiles"
    return 1
  fi

  local temp_skill="$HOME/.codex/skills/$skill_name"
  local dotfiles_skill="$DOTFILES_DIR/dot_codex/skills/$skill_name"

  if [ -L "$HOME/.codex/skills" ]; then
    echo "Note: ~/.codex/skills is entirely symlinked"
    if [ -d "$dotfiles_skill" ]; then
      echo "Skill already exists in dotfiles: $dotfiles_skill"
    else
      echo "Skill not found. It may already be in dotfiles."
    fi
    return 0
  fi

  if [ ! -d "$temp_skill" ]; then
    echo "Error: Skill not found in ~/.codex/skills/$skill_name"
    echo "Use 'codex-skill-try $skill_name' to create it first"
    return 1
  fi

  if [ -d "$dotfiles_skill" ]; then
    echo "Error: Skill already exists in dotfiles: $dotfiles_skill"
    return 1
  fi

  echo "Moving skill to dotfiles..."
  mv "$temp_skill" "$dotfiles_skill"

  echo "Skill promoted to dotfiles"
  echo "  Dotfiles location: $dotfiles_skill"
  echo ""
  echo "Next steps:"
  echo "  cd $DOTFILES_DIR"
  echo "  git add dot_codex/skills/$skill_name"
  echo "  git commit -m 'Add $skill_name skill'"
}

codex-skill-list() {
  echo "=== Codex CLI Custom Skills ==="
  if [ -d "$DOTFILES_DIR/dot_codex/skills" ]; then
    ls -1 "$DOTFILES_DIR/dot_codex/skills"
  else
    echo "No custom skills found"
  fi
}
