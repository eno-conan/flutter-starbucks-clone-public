# モデル制御ルール（影響度ベースのルーティング）

## 目的

作業の**影響度**に応じて使用モデルを切り替え、品質を落とさずにトークンコストを最適化する。
判断は個々のセッションの裁量ではなく、決定論的な分類器
`.claude/scripts/impact-classify.sh` の出力に従う。

```bash
bash .claude/scripts/impact-classify.sh lib/screens/home_screen.dart docs/foo.md
# TIER=standard / PLAN_MODEL=opus / IMPL_MODEL=sonnet / REVIEWERS=... / MAX_ROUNDS=3
```

引数なしで実行すると作業ツリーの差分（未追跡ファイル含む）から判定する。

## 役割とモデルの対応

| レイヤー | エージェント | モデル | 役割 |
|---|---|---|---|
| 計画・設計 | `plan-architect` | **opus** | 影響範囲調査・アーキテクチャ判断・手順分解・検証方法定義（コードは書かない） |
| 実装 | `implementer` | **sonnet** | 計画に従った実装。Dart/Flutter・スキーマ・テスト |
| 単調作業 | `docs-scribe` | **haiku** | docs / コメント / typo / nav 同期など判断の少ない定型作業 |
| レビュー | `code-reviewer` | **sonnet** | 差分の規約・設計レビュー（修正権限なし） |
| 品質評価 | `qa-agent` | **sonnet** | テスト・静的解析の実行と報告（修正権限なし） |
| セキュリティ | `security-agent` | **sonnet** | 脆弱性・認証情報露出の評価（修正権限なし） |
| Riverpod 専門 | `riverpod-specialist` | **sonnet** | Riverpod 3.0 準拠チェック・移行 |

## 影響度ティア

| ティア | 対象（`impact-classify.sh` のパスルール） | 計画 | 実装 | 必須レビュー | 最大ラウンド |
|---|---|---|---|---|---|
| **critical** | `supabase_schema/**`・`*.sql`・`android/**`・`ios/**`・`.github/workflows/**`・`pubspec.yaml`・`analysis_options.yaml`・`.claude/settings.json`・`.claude/hooks/**`・`.githooks/**`・`scripts/**`・`lib/services/**`・`lib/core/services/**`・`lib/constants/supabase_rpcs.dart` | opus | sonnet | code-reviewer + qa-agent + security-agent | 3 |
| **standard** | `lib/**`・`test/**`・`integration_test/**`・`web/**`・`.claude/agents,skills,rules,scripts/**` | opus | sonnet | code-reviewer + qa-agent | 3 |
| **trivial** | `docs/**`・`*.md`・`assets/**`・`public/**`・画像 | 不要 | haiku | code-reviewer（軽量） | 2 |

- **複数ティアが混在する変更は、最も高いティアに合わせる**（例: docs + スキーマ変更 → critical）
- DB スキーマ変更は「Opus が計画・Sonnet が実装」。Haiku には決して回さない
- ティア判定に迷うケースを見つけたら `impact-classify.sh` の `classify_one()` にパスルールを追加する
  （＝ルールをコードに落とす。セッションごとの判断に委ねない）

## モデル指定の方法

1. **エージェント定義の frontmatter**（既定）: `.claude/agents/*.md` の `model:` 行
2. **呼び出し単位の上書き**: Agent ツール呼び出し時に `model` パラメータを渡す
   （例: standard ティアだが文言修正だけ → `docs-scribe` を `haiku` のまま使う）
3. **スキル単位**: `SKILL.md` frontmatter の `model:` / `effort:`

Claude Code のモデル解決順（公式ドキュメント準拠）:
`CLAUDE_CODE_SUBAGENT_MODEL` 環境変数 → 呼び出し時の `model` パラメータ →
エージェント定義の `model` frontmatter → メインセッションのモデル

> ⚠️ `CLAUDE_CODE_SUBAGENT_MODEL` を `.claude/settings.json` の `env` に設定してはいけない。
> 全サブエージェントのモデル指定を上書きし、このルーティングが無効化される。

## モデル別名と実モデル

| 別名 | 解決先（2026-08 時点） |
|---|---|
| `opus` | Claude Opus 5 (`claude-opus-5`) |
| `sonnet` | Claude Sonnet 5 (`claude-sonnet-5`) |
| `haiku` | Claude Haiku 4.5 (`claude-haiku-4-5-20251001`) |

別名を使うこと。フルモデル ID を直書きすると世代交代時に追従できなくなる。

## トークン節約の原則

- **Opus は「読む量」を絞る**: 調査は `.claude/rules/repository-investigation.md` の top-down 手順に従い、
  構造ファイル（`lib/constants/supabase_rpcs.dart` → services → provider → screen）から辿る
- **メインコンテキストを汚さない**: 探索・レビューはサブエージェントにオフロードし、
  メインセッションには結論だけを戻す
- **Haiku に回せる作業を Sonnet でやらない**: docs / typo / nav 同期は `docs-scribe`
- **同じ調査を二度やらない**: 計画で得た情報は `implementer` へのプロンプトに要約して渡す
