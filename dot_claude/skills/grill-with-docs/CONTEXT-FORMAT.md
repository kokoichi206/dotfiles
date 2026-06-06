# CONTEXT.md フォーマット

<!-- Translated and adapted from mattpocock/skills (MIT).
     Original: https://github.com/mattpocock/skills/tree/main/skills/engineering/grill-with-docs/CONTEXT-FORMAT.md
     See ../THIRD_PARTY_NOTICES.md -->

## 構造

```md
# {コンテキスト名}

{このコンテキストが何であり、なぜ存在するかの 1〜2 文の説明}

## 用語

**Order**:
{この用語の 1〜2 文の説明}
_避ける語_: Purchase, transaction

**Invoice**:
納品後に顧客に送られる支払い請求。
_避ける語_: Bill, payment request

**Customer**:
注文を行う個人または組織。
_避ける語_: Client, buyer, account
```

## ルール

- **意見を持つ。** 同じ概念に複数の語が存在するとき、最良の 1 つを選び、その他は「避ける語」として列挙する。
- **衝突は明示的にフラグを立てる。** 用語が曖昧に使われている場合、「Flagged ambiguities」セクションに明確な解決を書く。
- **定義はタイトに保つ。** 最大 1〜2 文。それが「何であるか」を定義し、「何をするか」は書かない。
- **関係性を示す。** 用語名を太字にし、明らかな多重度は表現する。
- **このプロジェクトのコンテキスト固有の用語のみを含める。** 一般的なプログラミング概念 (timeout, error type, utility pattern) は、プロジェクトで頻繁に使われていても含めない。用語を追加する前に「これはこのコンテキスト固有の概念か、それとも一般的なプログラミング概念か」を問う。前者だけが該当する。
- **自然なクラスタが現れたら小見出しでグループ化する。** すべての用語が単一のまとまった領域に属するならフラットなリストでよい。
- **対話例を書く。** 開発者とドメイン専門家の会話を例示し、用語が自然にどう絡み合い、関連概念間の境界がどう明確になるかを示す。

## 単一コンテキスト vs 複数コンテキスト

**単一コンテキスト (多くのリポジトリ):** リポジトリのルートに `CONTEXT.md` を 1 つ置く。

**複数コンテキスト:** ルートの `CONTEXT-MAP.md` がコンテキストの一覧、所在、関係を示す:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — 顧客注文を受け付け追跡する
- [Billing](./src/billing/CONTEXT.md) — 請求書を生成し決済を処理する
- [Fulfillment](./src/fulfillment/CONTEXT.md) — 倉庫のピッキングと出荷を管理する

## Relationships

- **Ordering → Fulfillment**: Ordering が `OrderPlaced` イベントを発行し、Fulfillment がそれを受信してピッキングを開始する
- **Fulfillment → Billing**: Fulfillment が `ShipmentDispatched` イベントを発行し、Billing がそれを受信して請求書を生成する
- **Ordering ↔ Billing**: `CustomerId` と `Money` の共有型
```

スキルは構造を以下のように推定する:

- `CONTEXT-MAP.md` があればそれを読んでコンテキストを見つける
- ルートに `CONTEXT.md` だけがあれば単一コンテキストとみなす
- どちらも無ければ、最初の用語が解決された時点でルートの `CONTEXT.md` を遅延作成する

複数コンテキストが存在する場合、現在の話題がどれに属するかを推定する。不明なら尋ねる。
