GitHub Project の期日超過タスクを取得し、アクション化したダイジェストを自分の Gmail に送信してください。`/loop` で定期実行する想定の明示呼び出し用コマンドです。

手順:
1. 期日超過タスクを取得する。
   ```bash
   bash ~/.claude/skills/next-todo/scripts/fetch-overdue.sh
   ```
2. `[Done]` を除外する（完了済みは対応不要）。Done 以外が 0 件なら、本文を「対応が必要なタスクはありません」としてそのまま送信に進む。
3. Done 以外の各タスクについて、issue 本文・コメントを読んで判断材料を補い、「次に取るべき具体的な一手」に変換する。優先度は経過日数の長さではなく不可逆リスクの大きさで並べる（自動課金・解約期限 > 申込・エントリー締切 > 外部締切のない調査）。private リンク（アクセス不可なもの）は推測で埋めず「リンク先を要確認」と残す。
4. プレーンテキストのダイジェストを `/tmp/next-todo-digest.txt` に書き出す。各タスクに `期日 / 経過日数 / Status / タスク / 次の一手 / Issue URL` を含める。
5. 送信先を認証情報から実行時に導出し、Gmail に送信する（アドレスをこのファイルに書かない）。
   ```bash
   to=$(gog auth list -j | jq -r '.accounts[0].email')
   gog send --to "$to" --subject "next-todo digest $(date +%F)" --body-file /tmp/next-todo-digest.txt --no-input
   rm -f /tmp/next-todo-digest.txt
   ```
6. 返ってきた `message_id` を確認し、送信成功を報告する。送信が失敗した場合（`invalid_grant` 等）は握りつぶさず、`gog auth doctor` の結果とともに原因を報告する。トークン失効なら `gog auth add <account>` での再認証が必要なことを伝える。

追加指示: $ARGUMENTS
