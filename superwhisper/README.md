# SuperWhisper

管理対象は vocabulary / replacements のみ（`settings.json`）。

録音・履歴・モデルは **ここには置かない**。

## 配備

`setup.sh` が、すでに存在する SuperWhisper のデータディレクトリへこのファイルを symlink する。

- `~/superwhisper/settings/settings.json`（新規インストールのデフォルト）
- `~/Documents/superwhisper/settings/settings.json`（古いインストール）

```sh
cd ~/ghq/github.com/kokoichi206/dotfiles
bash setup.sh
```

## パスについて

| 状況 | パス |
|---|---|
| 新規インストール | `~/superwhisper` |
| パス変更前からの利用 | `~/Documents/superwhisper` |

アプリ内の確認先: **Configuration → App folder location**。

再インストールせず移す場合: SuperWhisper を終了してデータフォルダをコピーまたは移動し、**Change folder...** で新しいパスを指定する。履歴を残すなら再インストールよりこちらを優先する。

## GUI で編集したあと

SuperWhisper が `settings.json` を書き直して symlink が切れたら、新しい内容をこのリポジトリに取り込むか、`setup.sh` で symlink を張り直してからコミットする。

## replacements の `id` について

各置換エントリの `id`（UUID）は、アプリ側がエントリを識別するためのもの。git に含めても問題ない。

- 端末をまたいで同じ `id` を使う分には不具合は起きにくい
- GUI で追加したエントリにも同様に `id` が付く
- `id` を消したり重複させたりすると、アプリが再生成したり表示がおかしくなったりする可能性があるので、手編集時は残す
