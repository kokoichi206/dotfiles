#!/bin/sh
#
# Description:
#   Claude Code settings.json の絶対パスを移植可能な "$HOME" 表記へ正規化する。
#   hook の command はシェル評価されるため "$HOME" は実行時に展開される。
#   シングルクォート内は展開されないため、JSON エスケープしたダブルクォート \" へ変換すること。
set -eu
: "${HOME:?HOME must be set}"

sed -E \
  -e "s#'(${HOME})([^']*)'#@@DQ@@@@HOME@@\2@@DQ@@#g" \
  -e "s#${HOME}#@@HOME@@#g" \
  -e 's#@@HOME@@#$HOME#g' \
  -e 's#@@DQ@@#\\"#g'
