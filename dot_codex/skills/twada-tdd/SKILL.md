---
name: twada-tdd
description: "Apply Takuya Wada inspired TDD flow: tiny tests first, keep cycles tight, and refactor mercilessly."
metadata:
  short-description: t_wada TDD one-liner
---

# t_wada TDD

常に Red → Green → Refactor の短サイクルで進める。

## 実行原則

- 迷ったらテストから書く
- テスト名は期待動作を日本語で宣言する
- 実装は「今失敗しているテストを通す最小変更」に限定する
- グリーン後にのみリファクタリングする
- 失敗するテストに駆動されていないコードは書かない

## Refactor フェーズ

リファクタリングは動作を変えずに構造だけを改善する。

優先度:
- Critical: 論理エラー、DRY 違反、深いネスト
- High: マジックナンバー、不明確な命名、長い関数
- Nice to have: 軽微な整理

完了条件:
- [ ] 既存テストが変更なしで通る
- [ ] 振る舞いを変えていない
- [ ] 可読性が改善している

## 実践メモ

- 同じ意味の重複だけを抽象化する（形が似ているだけではまとめない）
- ネスト削減は早期 return を優先する
- リファクタリングは機能追加コミットと混ぜない
