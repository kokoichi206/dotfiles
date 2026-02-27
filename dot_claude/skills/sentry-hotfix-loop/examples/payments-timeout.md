# Example: Payments Timeout Incident

```bash
bash scripts/fetch_issue_context.sh BILLING-102 ./tmp/sentry
python3 scripts/build_repro_checklist.py ./tmp/sentry/issue.json ./tmp/repro.md
bash scripts/verify_fix.sh ./checks.txt ./tmp/verify.md
```

`checks.txt` には、再現と修正確認に必要なコマンドを 1 行ずつ記述する。
