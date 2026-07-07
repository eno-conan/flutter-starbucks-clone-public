---
description: docs/zensical/docs/ 配下の .md ファイルを書いたら zensical.toml nav を自動更新する
paths:
  - "docs/zensical/docs/**/*.md"
---

# zensical.toml nav 自動同期ルール

`docs/zensical/docs/` 配下に `.md` ファイルを **新規作成または編集** したら、
Write/Edit ツールの直後に必ず以下のコマンドを実行して `zensical.toml` の nav を更新すること。

```bash
python docs/zensical/scripts/update_zensical_nav.py "<書いたファイルの絶対パス>"
```

## 動作仕様

- ファイルが nav に**未登録**なら自動追加する
- ファイルが nav に**登録済み**なら何もしない（冪等）
- ディレクトリとセクションのマッピング:

| ディレクトリ | nav セクション |
|---|---|
| `docs/claude/` | Claude Code |
| `docs/project/` | プロジェクト |
| `docs/flutter/` | Flutter |
| `docs/architecture/` | アーキテクチャ |
| `docs/security/` | セキュリティ |
| `docs/starbucks_user_side/` | 画面仕様 |

## 注意事項

- `starbucks_user_side/signin/` のように **2階層以上ネスト** されたパスはスクリプトがスキップする。
  その場合は `zensical.toml` のネストされたセクションに手動で追加すること。
- 上記テーブルにないディレクトリを追加した場合は、スクリプト内の `SECTION_MAP` と
  `zensical.toml` の `nav` 両方に手動でセクションを追加すること。
