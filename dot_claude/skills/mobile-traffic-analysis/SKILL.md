---
name: mobile-traffic-analysis
description: iOS/Android アプリの通信を mitmproxy で解析する手順。セットアップ・CA 証明書・cert pinning 判別・flows の読み方。トリガー - 通信解析, mitmproxy, mitmdump, パケットキャプチャ, アプリの通信を読む, cert pinning
---

# モバイルアプリ通信解析

iOS/Android アプリの HTTPS 通信を mitmproxy で中継して読む定型手順。一般的な手順のみ。

## 1. セットアップ

```bash
brew install mitmproxy
```

- `mitmproxy`: TUI で対話的に見る
- `mitmweb`: ブラウザ UI で見る
- `mitmdump`: 非対話。記録・スクリプト向き（`-w <file>` でキャプチャ保存）

まず PC 側でプロキシを起動する（デフォルト `:8080`）。

```bash
mitmweb            # または mitmproxy
mitmdump -w flows  # ファイルに記録する場合
```

## 2. 端末をプロキシ経由にする

- 端末を PC と同じ Wi-Fi に接続。
- 端末の Wi-Fi 詳細でプロキシを手動設定し、host に PC の LAN IP、port に `8080` を指定。

## 3. CA 証明書のインストールと信頼

mitmproxy の CA を端末に入れて信頼させないと HTTPS は復号できない。

- 端末ブラウザで `http://mit.it/`（プロキシ経由時に配布される）から証明書を取得。
- **iOS**: プロファイルをインストール後、`設定 > 一般 > VPN とデバイス管理` で承認し、
  さらに `設定 > 一般 > 情報 > 証明書信頼設定` で当該 CA を有効化する（この最後の手順を忘れると信頼されない）。
- **Android**: user 証明書としてインストール。ただし API 24+ ではアプリが
  `networkSecurityConfig` で user CA を信頼しない限りアプリ通信は復号できない。
  システム CA として入れるには root / Magisk が要る。

## 4. cert pinning の判別と回避可否

- 証明書を正しく入れてもハンドシェイクで切れる / 特定の通信だけ見えない場合は
  **certificate pinning** の疑い。アプリが期待する証明書/公開鍵を固定しており、
  MITM 証明書を拒否している。
- pinning は中間者攻撃（通信の盗聴・改ざん）を防ぐための仕組み。解析側から見ると壁になる。
- 回避可否はアプリ依存:
  - Android: apk を展開して `networkSecurityConfig` を書き換え再署名、または Frida/objection で
    pinning バイパス（要環境構築）。
  - iOS 実機: 難度が高い。jailbreak + Frija/objection 前提になりやすい。
- 業務・自己所有アプリの検証など、正当な権限がある対象に限って行う。

## 5. キャプチャと flows の読み方

```bash
mitmdump -w flows          # 記録
mitmproxy -r flows         # TUI で読み返す
mitmweb -r flows           # ブラウザで読み返す
```

- フィルタ例（mitmproxy 内 / `-r` 時）:
  - `~u <regex>`: URL でフィルタ
  - `~d <host>`: ドメインでフィルタ
  - `~m POST`: メソッドでフィルタ
  - `~t json`: content-type でフィルタ
- 内部 API の把握には、対象操作を端末で 1 度行い、その前後の flow だけを絞って読むと速い。
