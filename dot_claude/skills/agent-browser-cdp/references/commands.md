# agent-browser コマンドリファレンス

## ナビゲーション

```bash
npx agent-browser open <url>          # URL に遷移
npx agent-browser back                # 戻る
npx agent-browser forward             # 進む
npx agent-browser reload              # リロード
```

## ページ情報取得

```bash
npx agent-browser snapshot            # アクセシビリティツリー（AI 向け、ref 付き）
npx agent-browser screenshot [path]   # スクリーンショット
npx agent-browser get text [sel]      # テキスト取得
npx agent-browser get html [sel]      # HTML 取得
npx agent-browser get url             # 現在の URL
npx agent-browser get title           # ページタイトル
npx agent-browser get value <sel>     # input の値
npx agent-browser get attr <name> <sel>  # 属性値
npx agent-browser get count <sel>     # 要素数
npx agent-browser get box <sel>       # 要素の位置・サイズ
```

## 操作

```bash
npx agent-browser click @ref          # ref で要素をクリック（snapshot で取得）
npx agent-browser click <selector>    # CSS セレクタでクリック
npx agent-browser dblclick <sel>      # ダブルクリック
npx agent-browser type <sel> <text>   # テキスト入力（追記）
npx agent-browser fill <sel> <text>   # テキスト入力（クリア後）
npx agent-browser press <key>         # キー入力（Enter, Tab, Control+a 等）
npx agent-browser hover <sel>         # ホバー
npx agent-browser select <sel> <val>  # ドロップダウン選択
npx agent-browser check <sel>         # チェックボックス ON
npx agent-browser uncheck <sel>       # チェックボックス OFF
npx agent-browser scroll <dir> [px]   # スクロール（up/down/left/right）
npx agent-browser wait <sel|ms>       # 要素 or ミリ秒待機
```

## JavaScript 実行

```bash
npx agent-browser eval "<js>"         # JS を実行して結果を返す
```

## 要素検索

```bash
npx agent-browser find role <role> click       # role で検索してクリック
npx agent-browser find text <text> click       # テキストで検索してクリック
npx agent-browser find label <label> fill <v>  # ラベルで検索して入力
npx agent-browser find placeholder <p> fill <v>  # placeholder で検索
```

## セッション管理

```bash
npx agent-browser connect <port>      # CDP で接続
npx agent-browser close               # ブラウザを閉じる
npx agent-browser close --all         # 全セッションを閉じる
```

## オプション

```bash
--headed              # ブラウザウィンドウを表示
--session <name>      # セッション名を指定（複数ブラウザ管理）
--json                # JSON 出力
```
