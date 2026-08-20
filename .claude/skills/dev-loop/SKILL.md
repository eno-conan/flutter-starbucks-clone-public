---
name: dev-loop
description: 実装 → 自動レビュー → 修正を品質ゲート通過まで回す Loop Engineering ワークフロー。影響度に応じて計画=Opus / 実装=Sonnet / 単調作業=Haiku にモデルを振り分ける。
argument-hint: [作業内容 または Issue番号]
disable-model-invocation: true
allowed-tools: Bash(bash .claude/scripts/impact-classify.sh *) Bash(git diff *) Bash(git status *) Bash(git log *)
---

# Loop Engineering ワークフロー

依頼内容: $ARGUMENTS

## 現在の状態（起動時に自動取得）

- 変更ファイル: !`git status --short | head -30`
- 影響度判定（現時点の差分ベース）: !`bash .claude/scripts/impact-classify.sh 2>/dev/null | head -6`

---

あなたは **Orchestrator（司令塔）** です。自分で実装せず、各フェーズを専任エージェントに委譲し、
品質ゲートを通過するまでサイクルを回してください。メインコンテキストには**結論だけ**を戻し、
ファイル全文や長いログを持ち込まないこと。

ルール参照: `.claude/rules/model-routing.md`（モデル制御） / `.claude/rules/quality-gate-layers.md`（品質ゲート層）

## Phase 0: 影響度の確定

これから触る**予定の**ファイルパスを列挙し、分類器にかける（起動時の判定は既存差分ベースなので必ずやり直す）:

```bash
bash .claude/scripts/impact-classify.sh <触る予定のパス...>
```

出力の `TIER` / `PLAN_MODEL` / `IMPL_MODEL` / `REVIEWERS` / `MAX_ROUNDS` を**このループの設定として固定**する。
以降のモデル選択はこの出力に従い、独自判断で変えない。変えるべきだと判断した場合は、
セッション内で例外にするのではなく `impact-classify.sh` のパスルール追加をユーザーに提案する。

## Phase 1: 計画（`PLAN_MODEL` が `none` 以外のとき）

`plan-architect`（Opus）を 1 回だけ呼ぶ。以下は**呼ばない**:

- ユーザーが実装計画を提示済みのとき（そのまま Phase 2 へ）
- `TIER=trivial` のとき

呼ぶときに渡す情報: 依頼内容 / 対象パス / `impact-classify.sh` の出力 / 既知の制約。
返ってきた計画に「未確定事項」があれば、**実装に入らずユーザーに確認**する。

## Phase 2: 実装

- `TIER=trivial` → `docs-scribe`（Haiku）
- それ以外 → `implementer`（Sonnet）

計画のステップ単位で委譲する。1 サブエージェント = 1 まとまりの作業。
`docs-scribe` が `ESCALATE:` を返したら `implementer` に切り替える。

実装エージェントには次を必ず渡す:

1. 計画の該当ステップ（全文ではなく該当部分）
2. 完了条件（観測可能な形で）
3. 前ラウンドのレビュー指摘（2 ラウンド目以降）

## Phase 3: 機械的検証（レビューより先）

人間/LLM のレビューを回す前に、**機械で分かることを先に潰す**:

```bash
dart analyze <変更ファイル>
flutter test <関連テスト>
```

エラーが出たら Phase 2 に戻る（このラウンドはレビューに進まない。ラウンド数には数えない）。
`dart` が使えない環境ではその旨を記録し、レビューへ進む。

## Phase 4: レビュー（並列実行）

`REVIEWERS` に含まれるエージェントを**1 メッセージ内で同時に**呼び出す:

| エージェント | 見るもの |
|---|---|
| `code-reviewer` | 差分の正しさ・プロジェクト規約・重複・過剰実装 |
| `qa-agent` | テスト・静的解析の実行結果 |
| `security-agent` | 認証情報露出・RLS・OWASP Mobile 観点（critical のみ） |

レビュアーには修正権限が無い。**Generator（実装エージェント）と Evaluator（レビュアー）を混ぜない**。

## Phase 5: 判定

**PASS 条件（すべて満たすこと）**:

- `code-reviewer` が `VERDICT: PASS`
- `qa-agent` が報告したテスト・静的解析でエラー 0
- `security-agent`（呼んだ場合）が high 指摘 0
- 依頼範囲外の変更が差分に含まれていない

1 つでも欠けたら **FAIL** → Phase 2 に戻り、ラウンド数を +1 する。

## Phase 6: ループ終了条件

| 条件 | 行動 |
|---|---|
| PASS | ループ終了。Phase 7 へ |
| ラウンド数が `MAX_ROUNDS` に到達 | **即 STOP**。ユーザーに報告 |
| オシレーション検知 | **即 STOP**。ユーザーに報告 |

**オシレーション検知**（`.claude/rules/` の workflow 方針と同一）:

- 同一ファイルへの同じ修正を 2 回以上繰り返した
- レビュー指摘が前ラウンドと同一のまま
- A → B → A の往復が発生した

STOP したときは以下を必ず出す:

1. 何を何回試したか
2. 残っている指摘（ブロッキングのみ）
3. 根本原因の仮説
4. 選択肢（別アプローチ / 仕様確認 / 設計やり直し）

さらに `tasks/lessons.md` に再発防止パターンを追記する（ファイルが無ければ作成）。

## Phase 7: 完了報告

```
## 完了
- ラウンド数: N / MAX_ROUNDS
- 影響度ティア: <tier>
- 使用モデル: 計画=<model> 実装=<model> レビュー=<models>

## 変更内容
- <ファイル>: <要約>

## 検証結果
- dart analyze: <結果>
- テスト: <結果>
- レビュー: <PASS/指摘対応の要約>

## 残課題
- <あれば。無ければ「なし」>
```

コミットはユーザーの指示があるときだけ行う。コミットする場合、pre-commit / commit-msg が
落ちても**迂回しない**（`.claude/rules/quality-gate-layers.md` の迂回ポリシー）。

## トークン運用（重要）

- Opus（`plan-architect`）は 1 ループ 1 回まで。再計画が必要なら STOP してユーザー判断を仰ぐ
- 差分・ログ・ファイル全文をメインコンテキストに貼らない。要約だけを持つ
- 同じ調査を各エージェントに繰り返させない。計画で得た情報を要約して渡す
- `TIER=trivial` の作業に Sonnet / Opus を使わない
