# 定点ソースと取得方法

すべて対象期間 (直近 7 日) で絞る。fetch できた内容のみ採用し、二次ソースはその旨をレポートに明記する。

## 必須ソース

| 担当 | ソース | 取得方法 | 403 等の fallback |
|---|---|---|---|
| ①Claude | https://claude.com/ja/blog | WebFetch | 期間内 0 件のことがある。code.claude.com の What's new と anthropic.com/news で補完 |
| ①Claude | https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md | WebFetch (raw を使う) | — |
| ①Claude | https://code.claude.com/docs/en/whats-new | WebFetch | — |
| ①Claude | https://www.anthropic.com/news | WebFetch | — |
| ②Codex | https://developers.openai.com/blog | WebFetch | — |
| ②Codex | https://github.com/openai/codex/releases | WebFetch (個別タグページ) | https://api.github.com/repos/openai/codex/releases?per_page=15 (body が truncate されたら個別タグを fetch)。alpha 系はページがロードエラーを返すことがある |
| ②Codex | https://openai.com/news/ | WebFetch は 403 (ブラウザ UA の curl でも 403 = bot 対策) | WebSearch (報道) で代替し「一次未検証」と明記 |
| ③xAI | https://x.ai/news | WebFetch は 403 (同上) | WebSearch allowed_domains:["x.ai"]、または grok CLI web fetch |
| ③xAI | https://x.ai/build/changelog | WebFetch は 403 | **grok CLI の web fetch なら読める** (下の grok CLI 節) |
| ③xAI | https://github.com/xai-org/grok-build | WebFetch | 公式 grok CLI = Grok Build。superagent-ai/grok-cli は非公式の別物 |
| ④他社 | Gemini CLI / Antigravity | https://releasebot.io/updates/google/gemini-cli など | 一次 changelog が引けたらそちらを優先 |
| ④他社 | モデルリリース裏取り | https://llm-stats.com/llm-updates | pricepertoken.com は WebFetch 403 (UA 判定なのでブラウザ経由なら見える) |
| ④他社 | MCP 仕様 | https://blog.modelcontextprotocol.io/ | — |
| ブログ定点観測 | https://azukiazusa.dev/blog/ | WebFetch (一覧 → 期間内記事を個別 fetch) | 国内実践記事の枠。ユーザーの構成との重なり/輸入候補を比較ボックスで書く |
| 検証 | https://simonwillison.net/ | WebFetch | ベンダー発表の独立検証に有用 |

## 調査 agent プロンプトの共通要件

- 期間を明示し、「知識カットオフ後の情報なので fetch した内容のみ報告。推測・記憶からの補完は禁止」を課す。
- 報告フォーマットに「取得失敗・制限」セクションを必須にする (なければ「なし」と書かせる)。
- 画像・動画は「リリースなし」も結論として報告させる (調べた範囲を列挙)。

## grok CLI (X 検索・x.ai 取得)

- ヘッドレス実行: `grok --cwd "$TMPDIR" -p "<プロンプト>"`。
- sandbox 内では `~/.grok` への書き込みが拒否されて起動できない。sandbox 解除が必要 (失敗時は runs.jsonl に記録して続行)。
- 出力が tail で切れたら: セッションは `~/.grok/sessions/<URL エンコードした cwd>/` に保存されている。
  `command ls -t` (ANSI カラー除去必須) で最新セッション ID を取り、`grok export <session-id> <出力先>` で全文回収する。
- X 検索プロンプトには「実際にヒットしたポストのみ」「@ハンドル・ポスト URL 付き」「期間指定」を必ず入れる。
  観点: マルチエージェントオーケストレーション / hooks・skills の工夫 / grok CLI (Grok Build) 実践 / 日本の開発者。
- x.ai 配下 (news, build/changelog) は WebFetch 403 でも grok の web fetch 経由なら読める。
  例: `grok --cwd "$TMPDIR" -p "https://x.ai/build/changelog を fetch して期間内エントリを全文転記して"`
