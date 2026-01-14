---
description: Update Supabase table definitions from migration files
argument-hint: [migration-file-name]
---

# データベーススキーマ定義の更新

このコマンドは、`supabase_schema/supabase/migrations/` フォルダに追加された新しいマイグレーションファイルを元に、`supabase_schema/supabase/supabase_table_definitions.md` のテーブル定義を最新化します。

## 現在の状態

### マイグレーションファイル一覧
最新のマイグレーションファイル（最新5件）:
!`ls -t supabase_schema/supabase/migrations/*.sql | head -5`

### 現在のテーブル定義ドキュメント
現在のテーブル定義の更新日:
!`grep "最終更新:" supabase_schema/supabase/supabase_table_definitions.md`

## タスク

以下の手順でテーブル定義を更新してください：

1. **マイグレーションファイルの確認**
   - 引数が指定された場合: `supabase_schema/supabase/migrations/$ARGUMENTS` を読み込む
   - 引数がない場合: 最新のマイグレーションファイルを読み込む

2. **テーブル定義の抽出**
   - CREATE TABLE文から以下の情報を抽出:
     - テーブル名（論理名と物理名）
     - カラム名と型
     - 主キー制約
     - 外部キー制約
     - NOT NULL制約
     - デフォルト値
     - CHECK制約
     - UNIQUE制約
   - CREATE FUNCTION/CREATE OR REPLACE FUNCTION文がある場合はRPC関数として記録

3. **既存定義との統合**
   - `supabase_schema/supabase/supabase_table_definitions.md` を読み込む
   - 新しいテーブルの場合: アルファベット順の適切な位置に追加
   - 既存テーブルの更新の場合: 該当箇所を更新
   - テーブル概要セクションにも反映

4. **更新履歴の記録**
   - 「主な更新点」セクションに今日の日付で追加
   - 変更内容を簡潔に記載
   - 総テーブル数を更新

5. **一貫性チェック**
   - テーブル名がアルファベット順に並んでいることを確認
   - カラムの論理名が適切な日本語になっていることを確認
   - 外部キー参照が正確であることを確認

## 注意事項

- テーブル定義は以下の形式で記述してください:

```markdown
## テーブル名

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 日本語名 | column_name | type | ○ | 参照先 | 制約やデフォルト値など |
```

- 論理名（日本語カラム名）は、カラムの用途から適切に判断してください
- 制約やデフォルト値は「備考」欄に記載してください
- CHECK制約で取りうる値が限定されている場合は、その値も明記してください

## 実行後の確認

更新完了後、以下を確認してください:
- [ ] 新しいテーブル定義が追加されている
- [ ] テーブルがアルファベット順に整理されている
- [ ] 「最終更新」の日付が今日になっている
- [ ] 「主な更新点」セクションに変更履歴が追加されている
- [ ] 総テーブル数が正しく更新されている
