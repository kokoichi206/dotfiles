# ============ iTerm2 Badge ============
is_iterm2() {
  [[ "$TERM_PROGRAM" == "iTerm.app" ]] || [[ -n "$ITERM_SESSION_ID" ]]
}

update_iterm2_badge() {
  if ! is_iterm2; then
    return
  fi

  local current_path="$PWD"
  local badge_text=""

  if [[ "$current_path" =~ ^/Users/kokoichi206/ghq/github\.com/([^/]+)/([^/]+)/git/(.+)$ ]]; then
    local owner="${match[1]}"
    local repo="${match[2]}"
    local subpath="${match[3]}"
    badge_text="[$repo] $subpath"
  elif [[ "$current_path" =~ ^/Users/kokoichi206/ghq/ ]]; then
    badge_text="[ghq] ${current_path#/Users/kokoichi206/ghq/}"
  else
    badge_text=""
  fi

  printf "\033]1337;SetBadgeFormat=%s\007" "$(echo -n "$badge_text" | base64)"
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd update_iterm2_badge
update_iterm2_badge

# ============ Tool initialization ============
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# direnv (nix-direnv) のフック
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

eval "$(mise activate zsh)"

# zoxide と starship は末尾で初期化（precmd hooks の順序のため）
# Claude Code 等のスナップショット再生シェルでは chpwd hook が復元されず
# zoxide doctor が誤検知して cd のたびに警告を出すため、doctor を無効化する
export _ZO_DOCTOR=0
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"

# WezTerm: OSC 7 で cwd を通知する。Pane Finder（leader+f）が各 pane の cwd を
# 正確に追跡するために必要。WezTerm 上でのみ有効化し、他端末には影響させない。
if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
  _wezterm_osc7() { printf '\033]7;file://%s%s\033\\' "${HOST}" "${PWD}" }
  add-zsh-hook precmd _wezterm_osc7
fi
