---
name: verify-wezterm-config
description: wezterm 設定変更を「退避 → 変更 → 目視確認 → OK なら commit / NG なら即 revert」の検証サイクルで進める手順。トリガー - wezterm 変えて, wezterm の設定, ガクガクする, 表示が崩れた, タブが等分されない, 画面サイズが変わる, 透過がおかしい, さっきの wezterm 戻して
---

# wezterm 設定変更の検証サイクル

wezterm の設定（`.config/wezterm/` 配下）は変更が即時 reload され、
崩れると作業環境そのものが壊れる。
必ず「戻せる状態を作ってから変更し、目視確認が取れるまで commit しない」サイクルで進める。

## 手順

1. **現状を退避する**
   - `git status` で wezterm 設定に未コミット変更がないか確認する。
   - 未コミット変更があれば、先に commit するか `git stash push .config/wezterm/` で退避し、
     「確実に戻れる点」を作ってから着手する。

2. **変更する**
   - 1 サイクルで変える論点は 1 つに絞る（複数同時に変えると、崩れたときにどれが原因か切り分けられない）。

3. **観察ポイントを提示して目視確認を依頼する**
   - wezterm の表示品質はコマンドでは検証できないため、変更内容に応じて以下の観察ポイントをユーザーに提示し、
     目視確認の結果を待つ。
     - タブ内 pane の等分（split / close 後に幅・高さが揃っているか）
     - リサイズ・分割時のガクつき（ジッター、数セルのドリフト）
     - ウィンドウサイズ（起動・attach 直後に `initial_cols` / `initial_rows` どおりか）
     - 透過（リサイズ中にデスクトップが透ける「穴」が出ないか）
   - `wezterm show-keys` 等の静的チェックは、`gui-attached` などの実行時イベントハンドラの誤り
     （`act.X` が nil 等）を検出できない。イベントハンドラを触った場合は GUI の再起動まで含めて確認を依頼する。

4. **NG なら即 revert する**
   - 原因調査より先に、まず表示を元に戻す。

     ```bash
     git checkout -- .config/wezterm/   # 未コミットなら
     git revert <commit>                # commit 済みなら
     ```

   - 戻したうえで、原因の仮説を立ててから次のサイクルに入る。

5. **OK なら commit する**
   - 目視確認が取れた変更だけを commit する。確認が取れていない変更を「たぶん大丈夫」で積まない。

## 既知の制約（unix domain mux 構成）

`unix_domains` + `default_gui_startup_args = {"connect", "unix"}` の mux 構成では、
plain モードで動く実装がそのままでは動かないことがある。

- **probe ベースの pane 均等化は mux 接続では機能しない。**
  `window:perform_action` が IPC 越しの非同期になり、probe 直後の `panes_with_info` が古い値を返して
  全 probe の検証が失敗する。調整は行われず、adjust/undo ペアの遅延適用によるジッターと数セルのドリフトだけが残る。
  mux で均等化するなら、`call_after` で再測定しながら収束させる feedback loop への再設計が必要。

- **attach 経路では `initial_cols` / `initial_rows` が無視される**（`TermWindow::new_window` が
  mux 側の tab サイズを採用するため。wezterm issue #6826）。
  対処は `gui-attached` イベントで `ResetFontAndWindowSize` を `window:perform_action(action, pane)` で
  実行すること。これは `config.initial_size()` を DPI・フォントメトリクスから px 換算し、
  OS window・pty・mux サーバー側サイズまで揃える。`window:maximize()` や `set_inner_size`
  （device px 手計算・DPI 依存）より確実。

- **pane 比率の破壊（縦分割が横に伸びる等）は attach 時ではなく detach（GUI クローズ）時に起きる**
  （wezterm issue #5117）。「均等な状態」を保存しておくことはできず、attach 後に再導出するしかない。

- **リサイズ時の「透明な穴」は透過設定（`window_background_opacity < 1.0`）が直接原因。**
  mux ラグで背景描画が遅れた領域が alpha 0 になる。透過を維持したまま緩和するには
  `use_resize_increments = true`（セル単位スナップで中間 resize と Resize RPC を削減）。

- **本番 mux 稼働中に隔離 mux を立てる検証はできない。**
  `wezterm-mux-server` は pid / socket パスを `~/.local/share/wezterm/` に固定しており env で逃がせない。
  実発火の検証は実 GUI の再起動に委ねる。
