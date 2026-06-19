# dotfiles リポの Claude セッション運用メモ

このリポで Claude Code を動かすときの運用記録。スケジュールタスクの状態
（`scheduled_tasks.json` 等）もこの `.claude/` に落ちるため、関連メモをここに集約する。

## next-todo-mail（期日超過タスクのメールダイジェスト）

`dot_claude/commands/next-todo-mail.md`（user スコープの command）が、GitHub Project の
期日超過タスクをアクション化して自分の Gmail に送る。送信は gogcli（OAuth、宛先は
`gog auth list` から実行時導出するのでリポにアドレスは書かない）。

### 定期実行の登録

セッション内で次を打つ:

```
/loop 12h /next-todo-mail
```

- `/loop` は間隔指定 → cron `0 */12 * * *` に変換され、00:00 / 12:00 に実行される。
- 間隔は任意（`/loop 6h /next-todo-mail` 等）。間隔ベースなので時刻の厳密指定はしない。
- 時刻を固定したい場合のみ、CronCreate で `3 9,18 * * *`（9:03 / 18:03）等を直接登録する。
- 解除: `/loop` 登録時に表示されるジョブ ID を CronDelete に渡す。
- session-only かつ起動中のセッションでのみ発火。閉じている間はスキップ。7 日で自動失効。
- 完全放置で毎日確実に回したいなら launchd 化（plist をリポ管理）に切り替える。

### 前提

- gogcli が認証済み（`gog auth list` でアカウントが見えること）。送信先＝認証アカウント（自分）。
- macOS Keychain は初回と gogcli アップグレード後に「常に許可」が必要。以後はプロンプトなし。
- OAuth 同意画面は "In production" にしておく（"Testing" だと 7 日でリフレッシュトークン失効）。
- トークン失効（送信時に `invalid_grant`）した場合は `gog auth add <account>` で再認証。
