---
name: mobile-simulator
description: iOS Simulator / Android Emulator・実機を CLI で操作する定型手順。起動・install・launch・スクショ確認・ログ・deep link・画面入力。トリガー - simulator, エミュレータ, simctl, adb, スクショで確認, アプリ起動して確認, logcat, deep link 検証, 実機で確認, アプリの画面を見て
---

# モバイル Simulator / Emulator 操作

iOS Simulator と Android Emulator/実機を CLI で駆動し、画面とログで挙動を確認する定型手順。
GUI を手で触らず、`launch → 待機 → スクリーンショット取得 → 画像を読んで確認` のループを基本とする。

プロジェクト固有値（bundle id・package・scheme・device serial・deep link scheme）はリポジトリごとに異なるので、
このドキュメントでは placeholder（`$SIM` `$D` `$BUNDLE` `$PKG`）で書く。実値は §0 の一覧コマンドで調べて置き換える。

## 0. 対象デバイスの特定

複数の Simulator/端末が同時に起動・接続していると、明示指定しない限りコマンドは曖昧なまま失敗する。最初に必ず対象を確定する。

iOS:

```bash
xcrun simctl list devices booted      # 起動中のみ
xcrun simctl list devices available   # 利用可能な全 UDID
```

以降 `$SIM` を UDID に。単一起動なら UDID の代わりに `booted` を使える。

Android:

```bash
adb devices                           # emulator-5554 等 / 実機は英数字 serial
```

以降すべて `-s $D` で serial を固定する。`-s` を省くと複数接続時に "more than one device/emulator" で失敗する。
起動中プロセスの pid は `adb -s $D shell pidof $PKG` で取れる。

## 1. iOS Simulator (simctl)

### 起動・install・launch

```bash
xcrun simctl boot $SIM 2>&1 | head -1        # 未起動なら。起動済みなら無害に失敗する
xcrun simctl install $SIM <path/to/App.app>
xcrun simctl launch $SIM $BUNDLE >/dev/null 2>&1; sleep 6   # 描画が落ち着くまで待つ
xcrun simctl terminate $SIM $BUNDLE          # 再起動したいとき
```

`sleep` の秒数は初回起動・重い画面ほど長めにする（起動直後にスクショを撮ると前画面が写る）。

### スクリーンショット（確認の主手段）

```bash
xcrun simctl io $SIM screenshot <path>.png
```

`simctl boot` だけのヘッドレス状態でも撮れる（Simulator.app を前面に出す必要はない）。撮った png を読んで UI を確認する。

### UI 状態（ダークモード・文字サイズ）

```bash
xcrun simctl ui $SIM appearance light          # light | dark
xcrun simctl ui $SIM content_size medium        # medium(標準) 〜 accessibility-extra-extra-extra-large(AX5, 310%)
```

起動中のアプリにも即反映される。ダーク/ライトや Dynamic Type の各段でスクショを撮り比べる用途。

### deep link

```bash
xcrun simctl openurl $SIM '<scheme>://<path>'
```

## 2. Android Emulator / 実機 (adb)

### install（状態を維持したい場合は -r）

```bash
adb -s $D install -r <path/to/app-debug.apk>
```

`-r` は再インストール（上書き）で、アプリのデータ・ログインセッションを保持する。ビルドし直して差分だけ確認したいときに使う。

### launch / force-stop

```bash
adb -s $D shell am start -n $PKG/.MainActivity   # 実際の Activity 名はマニフェスト参照
adb -s $D shell am force-stop $PKG; sleep 1      # クリーンな状態から起動し直すとき
```

### スクリーンショット

```bash
adb -s $D exec-out screencap -p > <path>.png
```

`exec-out` はバイナリをそのまま stdout に流すので端末上のファイルを経由しない。

### ログ（clear → 再現 → dump のループ）

```bash
adb -s $D logcat -c                              # 一度クリアして
# ここで対象の操作を再現
adb -s $D logcat -d 2>/dev/null | grep -iE '<pattern>'   # 溜まったログを dump して絞る
adb -s $D logcat -d -s <TAG>                     # 特定タグだけ見る
```

クラッシュや特定イベントの調査は「clear してから再現し、dump を grep」で切り分ける。`-d` は dump して抜ける（tail しっぱなしにしない）。

### deep link

```bash
adb -s $D shell am start -a android.intent.action.VIEW -d '<scheme>://<path>'
```

### 画面入力

```bash
adb -s $D shell input tap <x> <y>
adb -s $D shell input swipe <x1> <y1> <x2> <y2> [duration_ms]
adb -s $D shell input text '<文字列>'             # 空白等はエスケープに注意
adb -s $D shell input keyevent KEYCODE_BACK       # HOME / DEL / MOVE_END など
```

座標はスクショで位置を確認してから指定する。

## 3. ビルド（必要なとき）

iOS:

```bash
xcodebuild -list -project <X>.xcodeproj                       # scheme を確認
xcodebuild build -scheme <X> -destination 'platform=iOS Simulator,name=<デバイス名>'
xcodebuild test  -scheme <X> -destination 'platform=iOS Simulator,name=<デバイス名>'
```

Android:

```bash
./gradlew assembleDebug        # apk は app/build/outputs/apk/debug/app-debug.apk に出る
```

## 注意

- 具体値（bundle id・package・serial・scheme）はリポジトリの CLAUDE.md やマニフェストで確認する。ここに書かない（変わると嘘になる）。
- スクショ確認は「launch 直後に撮らず sleep を挟む」。前画面やスプラッシュが写ると誤読する。
- 複数端末が繋がっている環境では毎コマンド `-s $D` / `$SIM` を付ける。省略は事故のもと。
