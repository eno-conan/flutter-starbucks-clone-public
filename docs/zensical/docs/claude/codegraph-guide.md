# CodeGraph ガイド

## なぜ CodeGraph を使うのか（オントロジーの背景）

### フラットな Markdown の限界

CLAUDE.md や rules/ への箇条書きは「資料をフラットに並べているだけ」。
概念同士の**関係**が定義されていないため、Claude が推論するたびに解釈のブレが生じる。

### オントロジーが解決すること

オントロジーは「概念と概念どうしの関係を明示的に定義したもの」。

| 要素 | 内容 |
|---|---|
| クラス | 概念の型（例: Provider, Service, Screen） |
| インスタンス | 具体例（例: authStateProvider） |
| プロパティ | 属性（例: 戻り値の型） |
| **関係** | `calls` / `depends-on` など型付きの繋がり |
| 制約 | 成り立つ条件 |

決定的な違いは**関係の型化**。grep では「どのファイルに文字列が出現するか」しかわからないが、
オントロジー的グラフは「A が B を呼び出している」という意味を持つ。

### CodeGraph はオントロジー的グラフを実現する

- `calls` / `depends-on` 等の関係をコードから自動抽出
- Claude が grep/Read ループなしに「A はどこから呼ばれているか」を一発で取得できる
- 選択肢が構造的に絞られるため幻覚（もっともらしい嘘）が抑制される

**Zenn 記事での測定値**（claude-ontology-knowledge-structuring）:
- トークン: 768k → 118k（約 84% 削減）
- コスト: 約半分
- 応答速度: 2分7秒 → 44秒（約 3 倍高速化）

---

## CodeGraph とは

> "local-first code intelligence library, CLI, and MCP server"
> — Colby McHenry 作、OSS

コードベースを事前インデックス化し、AI コーディングエージェントに
「surgical context（外科的な文脈）」を一発で渡す仕組み。

### アーキテクチャ（3層）

1. **インデックスエンジン**: tree-sitter で AST 解析 → シンボル定義・関数シグネチャ・インポート関係を抽出
2. **ストレージ層**: SQLite + FTS5 でローカルの `.codegraph/` ディレクトリに保存（100% ローカル動作）
3. **MCP サーバー**: `codegraph_explore` ツールを Claude Code / Cursor 等に提供

### 効果（GitHub README より）

| 指標 | 削減量 |
|---|---|
| ツール呼び出し | 58% 削減 |
| 実行時間 | 22% 高速化 |
| ファイル読み取り | ほぼゼロ |
| API コスト | 35% 削減 |
| トークン消費 | 59% 削減 |

grep/glob/Read ループによる「discovery tax（発見税）」を排除することで実現。

### 対応言語

TypeScript、JavaScript、Python、Rust、Go、Java、C、C++、Ruby、PHP、Swift、Kotlin ほか 20+ 言語

---

## インストール・セットアップ

### 前提条件

- Node.js 22 または 24

### 手順

```bash
# Step 1: CLI をグローバルインストール
npm install -g @colbymchenry/codegraph

# macOS/Linux は curl でも可
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh

# Step 2: MCP サーバーを各エージェントに自動登録
# （Claude Code / Cursor / Codex CLI / Kiro などを自動検出）
codegraph install

# Step 3: プロジェクトをインデックス化
codegraph init

# 対話モード（除外パターンを選びたい場合）
codegraph init -i

# Step 4: 動作確認
codegraph status
# → "Backend: native" と表示されれば OK
# → シンボル数が 0 の場合は codegraph init を再実行
```

### codegraph install が行うこと

- Claude Code: `.claude/CLAUDE.md` を自動生成（codegraph の使い方を指示する内容）
- `.mcp.json` に MCP サーバー設定を追記

> **注意**: `codegraph install` が生成する `.claude/CLAUDE.md` はルートの `CLAUDE.md` とは**別ファイルで共存**する。
> Claude Code は両方を読み込む（連結・上書きなし）。どちらも有効。

---

## コマンドリファレンス

| コマンド | 内容 |
|---|---|
| `codegraph init [path]` | プロジェクトのグラフを構築 |
| `codegraph sync` | 差分インデックスを更新 |
| `codegraph status` | インデックス統計を表示 |
| `codegraph explore "<query>"` | 関連シンボルとコールパスを検索 |
| `codegraph callers <symbol>` | そのシンボルを呼び出している箇所を追跡 |
| `codegraph callees <symbol>` | そのシンボルが呼び出している箇所を追跡 |
| `codegraph upgrade` | 最新バージョンに更新 |
| `codegraph install` | MCP サーバーをエージェントに登録 |

### 使用例

```bash
# authStateProvider がどこから呼ばれているか
codegraph callers authStateProvider

# ログイン処理の全体像を把握
codegraph explore "login authentication flow"

# OrderNotifier の依存関係を確認
codegraph callees OrderNotifier
```

---

## MCP ツール（Claude Code から呼ばれる）

### `codegraph_explore`

1 回の呼び出しで以下を返す:
- 関連シンボルの**逐語ソース**（行番号付き）
- シンボル間の**コールパス**（dynamic dispatch ホップも追跡）
- **ブラストラジウス**（影響範囲のサマリー）

ファイル変更は **2 秒デバウンス**で自動同期。

### Claude Code での使い方（MCP ガイドライン）

```
.claude/CLAUDE.md に以下が記載される:

"In repositories indexed by CodeGraph (a .codegraph/ directory exists at the repo root),
reach for it BEFORE grep/find or reading files when you need to understand or locate code"
```

つまり、grep / Glob / Read を使う前に **まず `codegraph_explore` を呼ぶ** のが推奨順序。

---

## .codegraph/ ディレクトリの管理

```
.codegraph/
  ├── index.db      # SQLite データベース（インデックス本体）
  └── .gitignore    # index.db を除外推奨
```

- **git にコミットする場合**: 新規開発者が即座にメリットを得られる（公式推奨）
- **git に含めない場合**: `.codegraph/` を `.gitignore` に追加し、各自 `codegraph init` を実行

---

## 使うべき場面・スキップすべき場面

### 使うべき場面

- 数百〜数千ファイルを持つリポジトリ
- アーキテクチャをまたぐ問いが多い（「この関数はどこから呼ばれる？」等）
- 毎日複数の AI コーディングセッションを実行する
- チームでコードベースを共有している

### スキップすべき場面

- コードが頻繁かつ大量に変わる（インデックスが追いつかない）
- ランタイム動作に関する質問（グラフは静的解析のみ）
- 小規模プロジェクト（ノイズになりやすい）
- すでに CLAUDE.md 等で充実したプロジェクトコンテキストがある場合

---

## RAG との使い分け（補足）

| 手法 | 強み | 弱み |
|---|---|---|
| オントロジー / CodeGraph | 関係を辿る・多ホップ推論 | 静的解析のみ |
| RAG（ベクトル検索） | 意味の近さで単一事実を抽出 | 複数ファイルをまたぐ集約が苦手 |
| GraphRAG（両者の組み合わせ） | 包括性と多様性で優位 | 構築コストが高い |

CodeGraph は「オントロジー寄り」の位置づけ。

---

## 参考リンク

- [tosea.ai — CodeGraph 完全ガイド 2026](https://tosea.ai/blog/codegraph-claude-code-cursor-guide-2026)
- [GitHub: colbymchenry/codegraph](https://github.com/colbymchenry/codegraph)
- [Zenn: Claude × オントロジーで知識を構造化する](https://zenn.dev/takupeso/articles/claude-ontology-knowledge-structuring)
