# よくあるパターン集

## 1. ログイン済みサイトでデータ取得

```bash
# Chrome プロファイルのコピーで CDP 起動
bash scripts/start-chrome-cdp.sh "Profile 1" 9222

# agent-browser から接続
npx agent-browser connect 9222

# サイトに遷移（Cookie が有効なのでログイン済み）
npx agent-browser open "https://app.example.com/dashboard"

# データ取得
npx agent-browser eval "document.querySelector('table').innerText"
```

## 2. 内部 API の発見（SPA かどうかの判定）

```bash
# ページの fetch/XHR リクエストを Resource Timing API で確認
npx agent-browser eval "
  const fetches = performance.getEntriesByType('resource')
    .filter(r => r.initiatorType === 'fetch'
      && !r.name.includes('google-analytics')
      && !r.name.includes('datadoghq')
      && !r.name.includes('amplitude'))
    .map(r => ({ url: r.name.substring(0, 150), type: r.initiatorType }));
  JSON.stringify({ count: fetches.length, fetches }, null, 2)
"
```

fetch が多数見つかる → SPA（パターン B: 内部 API で接続）
fetch がほぼない → SSR（パターン C: DOM パースで接続）

## 3. fetch/XHR のリアルタイム監視

```bash
# モンキーパッチで以降の fetch を全キャプチャ
npx agent-browser eval "
  (() => {
    window.__captured = [];
    const skip = ['datadoghq','google-analytics','googletagmanager','gstatic','amplitude'];
    const orig = window.fetch;
    window.fetch = function(...args) {
      const url = typeof args[0] === 'string' ? args[0] : args[0]?.url || '';
      const method = args[1]?.method || 'GET';
      if (!skip.some(s => url.includes(s))) {
        window.__captured.push({ url: url.substring(0, 200), method });
      }
      return orig.apply(this, args);
    };
    return 'Patched';
  })()
"

# 操作を行う（クリック、スクロール等）
npx agent-browser click @e42
npx agent-browser scroll down 5

# キャプチャ結果を確認
npx agent-browser eval "JSON.stringify(window.__captured, null, 2)"
```

## 4. DOM からテーブルデータを抽出

```bash
npx agent-browser eval "
  (() => {
    const tables = document.querySelectorAll('table');
    return JSON.stringify(Array.from(tables).map(table => {
      const headers = Array.from(table.querySelectorAll('th')).map(th => th.textContent.trim());
      const rows = Array.from(table.querySelectorAll('tbody tr')).map(tr =>
        Array.from(tr.querySelectorAll('td')).map(td => td.textContent.trim())
      );
      return { headers, rowCount: rows.length, rows: rows.slice(0, 5) };
    }), null, 2);
  })()
"
```

## 5. Cookie の取得（JS 可視分）

```bash
npx agent-browser eval "
  document.cookie.split(';').map(c => {
    const [name, ...rest] = c.trim().split('=');
    return { name, value: rest.join('=').substring(0, 30) + '...' };
  })
"
```

注意: HttpOnly cookie は JS からは見えない。Chrome 拡張の `chrome.cookies` API が必要。

## 6. ページのアーキテクチャ判定

```bash
npx agent-browser eval "
  JSON.stringify({
    react: typeof window.__REACT_DEVTOOLS_GLOBAL_HOOK__ !== 'undefined',
    vue: typeof window.__VUE__ !== 'undefined',
    angular: typeof window.ng !== 'undefined',
    nextjs: !!document.querySelector('#__next'),
    nuxtjs: !!document.querySelector('#__nuxt'),
    hasCsrf: !!document.querySelector('meta[name=\"csrf-token\"]'),
    scripts: document.querySelectorAll('script').length,
    tables: document.querySelectorAll('table').length
  }, null, 2)
"
```

## 7. Slack メッセージの読み取り

```bash
npx agent-browser open "https://app.slack.com/client"
sleep 3

# チャンネル一覧
npx agent-browser snapshot | head -80

# 特定のチャンネルをクリック
npx agent-browser click @e59

# メッセージ本文を取得
npx agent-browser eval "
  (() => {
    const main = document.querySelector('[class*=\"workspace__primary\"]')
      || document.querySelector('main');
    return main?.innerText?.substring(0, 2000) || 'not found';
  })()
"
```

## 8. スクリーンショットで状態確認

```bash
# フルページ
npx agent-browser screenshot /tmp/page.png

# 特定セッション
npx agent-browser screenshot /tmp/page.png --session my-session
```

## 9. 複数セッション（複数サイト同時操作）

```bash
# セッション A: freee
npx agent-browser open "https://secure.freee.co.jp" --session freee

# セッション B: Notion
npx agent-browser open "https://www.notion.so" --session notion

# それぞれ操作
npx agent-browser eval "document.title" --session freee
npx agent-browser eval "document.title" --session notion
```
