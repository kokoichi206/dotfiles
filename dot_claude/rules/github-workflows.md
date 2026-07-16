---
paths:
  - "**/.github/workflows/*.yml"
  - "**/.github/workflows/*.yaml"
---

# .github/workflows（GitHub Actions）を触るときの鉄則

`.github/workflows/` の workflow を編集・新規作成するときに従う。

- **機微でない値は secret にせず変数にする**: USERNAME・メールアドレス・リポジトリ名・環境名など機微でない値は `secrets` ではなく `env`（job/step の `env:`）か `vars`（repository/environment variables）で扱う。`secrets` に入れるのはパスワード・トークン・API キーなど本当に機微なものだけ。
  - Why: `secrets` はログで自動マスクされるため、無用に secret 化すると障害時に値が見えずデバッグしづらくなる。secret が増えるほど棚卸し・権限管理のコストも上がる。
