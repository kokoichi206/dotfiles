---
name: testing
description: 実装ではなく振る舞いをテストする原則とパターン
---

# テストパターン - 完全リファレンス

## 基本哲学

**「実装ではなく振る舞いをテストする。ビジネス動作を通じて100%カバレッジを達成し、実装の詳細ではない」**

コードが*何をするか*を検証し、*どうやるか*を検証しない。

## 主要原則

### パブリック API のみをテストする

意図されたインターフェースを通じて振る舞いを実行する。内部リファクタリング後もテストが有効なままになる。実装の変更ではなく、真のバグを検出する。

### テストデータのファクトリパターン

`beforeEach` を使った可変共有状態の代わりに、`Partial<T>` オーバーライドを受け取るファクトリ関数を使用する。

各テストは、本番のスキーマに対して検証された、新鮮で完全なオブジェクトを取得する。テスト用に再定義されたスキーマではない。

```typescript
// Good
function createUser(overrides: Partial<User> = {}): User {
  return {
    id: 'test-id',
    name: 'Test User',
    email: 'test@example.com',
    ...overrides,
  }
}

test('ユーザー作成', () => {
  const user = createUser({ name: 'Alice' })
  // ...
})
```

### カバレッジの演出を検出する

誤解を招くパターンに注意:

- テスト対象の関数をスパイする
- 関数が呼ばれたことだけをアサートする（結果ではない）
- 些細な getter/setter をテストする
- 行カバレッジを達成しているが分岐を見逃している

### 振る舞いによる組織化

実装ファイルではなく、ユーザーワークフローを中心にテストを構造化する。

単一の振る舞いテストファイルが、1:1 のファイルマッピングなしで複数の内部モジュールを実行できる。

## 避けるべきこと

- ❌ プライベートメソッドや内部状態をテストする
- ❌ テスト対象の関数をモックする
- ❌ `beforeEach` で `let` を使用する（共有可変状態を作成）
- ❌ 必須フィールドが欠けた不完全なテストオブジェクト
- ❌ ハッピーパスのみをテストする。エッジケースを含める
- ❌ 本番コードに既にあるスキーマを再定義する

## 実践例

### Bad

```typescript
test('バリデータが呼ばれる', () => {
  const validateSpy = jest.spyOn(validator, 'validate')
  processPayment(amount)
  expect(validateSpy).toHaveBeenCalled()
})
```

### Good

```typescript
test('負の金額を拒否する', () => {
  const result = processPayment(-100)
  expect(result.error).toBe('金額は正の値である必要があります')
})

test('有効な支払いを処理する', () => {
  const result = processPayment(1000)
  expect(result.success).toBe(true)
  expect(result.transactionId).toBeDefined()
})
```

振る舞いを通じてバリデーションレイヤー全体を検証する。バリデータ関数が呼ばれたかではなく、`processPayment()` が負の金額を拒否し、適切なエラーメッセージを返すことをテストする。

## チェックリスト

- [ ] パブリック API を通じてテストしている
- [ ] ファクトリパターンでテストデータを作成している
- [ ] プライベートメソッドをテストしていない
- [ ] 振る舞いの結果をアサートしている
- [ ] エッジケースをカバーしている
- [ ] テストが実装の詳細に依存していない
