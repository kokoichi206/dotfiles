# Triage Playbook

## 初動

1. shortId と発生時刻を固定する
2. 影響ユーザー数と発生頻度を確認する
3. 直近リリースとの差分を確認する
4. イベントタイプを確認する（exception vs message）

## 優先度

- P0: 全面障害、金銭影響、データ破損
- P1: コア機能停止
- P2: 回避可能だが影響あり
- P3: 軽微

## イベントタイプ別の調査

### exception (type: error)

- スタックトレースを起点に原因を追う
- 失敗イベントの共通タグを確認
- 失敗前後のリクエストを確認

### message (type: default)

captureMessage / logger.error 経由のイベント。stacktrace がない。

1. issue title のメッセージ文字列でコードを grep する
2. 呼び出し元の条件分岐を確認する
3. breadcrumbs からユーザー操作の流れを再構成する
4. tags からブラウザ・OS・URL などの共通パターンを探す

## フロントエンド (React/SPA) 固有のパターン

- breadcrumbs の UI 操作ログ（click, navigation）が原因推定に有用
- componentStack がある場合はコンポーネントツリーを追う
- logger.error / captureMessage の呼び出し箇所を grep して、エラーバウンダリやカスタムエラーハンドラを確認する
- ネットワークリクエストの breadcrumbs から API 失敗が起因かどうかを判定する
