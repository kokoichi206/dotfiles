---
name: typescript-strict
description: TypeScript strict モードでの堅牢なコード記述パターン
---

# TypeScript Strict Mode

TypeScript strict モードを有効にした堅牢なコード記述のための包括的ガイド。

## 基本原則

**3つの基礎ルール**:

1. **`any` 型を使わない** - 型情報が本当に不明な場合は `unknown` を使用
2. **型アサーションを最小化** - 明確な理由なく `as Type` 構文を避ける
3. **アーキテクチャの区別** - `interface` は振る舞いの契約に、`type` は不変データ構造に使用

## 主要アーキテクチャパターン

### スキーマの組織化

バリデーションロジックを一元化して、エンドポイントやアダプター間での重複を防ぐ。`src/schemas/` でスキーマを一度定義し、どこからでもインポートして「バリデーションの唯一の情報源」を確保する。

### 依存性注入

関数内で依存関係をインスタンス化しない。すべての協力者はパラメータとして注入する。これにより、インメモリ、データベース、リモートAPIなど「どの実装でも動作」し、完全なテスト可能性を維持できる。

### Type vs Interface

- **Interface**: 実装契約を定義（リポジトリ、ゲートウェイ、サービス）
- **Type**: `readonly` プロパティを持つ不変データ構造を記述

## 不変性と関数型プログラミング

- すべてのデータ構造プロパティに `readonly` を使用
- ミュータブルな配列より `ReadonlyArray<T>` を優先
- 予期されるエラーには例外ではなく `Result<T, E>` 型を使用
- 複雑なモノリシックなロジックより小さな純粋関数を組み合わせる
- 命令的ループより配列メソッド（`map`、`filter`、`reduce`）を使用

## 設定と安全性

`tsconfig.json` の重要な設定:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

これらの設定は、微妙なランタイムエラーをコンパイル時に検出する。

## 実践チェックリスト

- [ ] `any` 型を使用していない（`unknown` を検討）
- [ ] 型アサーション（`as`）には明確な理由がある
- [ ] すべての依存関係が注入されている
- [ ] データ構造に `readonly` を使用している
- [ ] `interface` と `type` を適切に使い分けている
- [ ] スキーマが一箇所で定義されている
- [ ] 配列操作に関数型メソッドを使用している
