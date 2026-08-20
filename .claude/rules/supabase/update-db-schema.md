---
paths:
  - "supabase_schema/supabase/**/*"
---

# データベーススキーマ定義の更新

`supabase_schema/supabase/supabase_table_definitions.md` と `entity_relationship/*.mmd` / `*.svg` は
**実スキーマからの自動生成物**です。手で編集しないでください。

## 正の所在

| 情報 | 正 |
|---|---|
| テーブル・カラム・型・制約・インデックス | マイグレーション（を適用した実スキーマ） |
| 論理名（日本語のカラム名） | マイグレーションの `COMMENT ON COLUMN` |
| テーブルの説明 | マイグレーションの `COMMENT ON TABLE` |
| 機能別ER図の構成・概要セクションの分類 | `supabase_schema/scripts/schema-doc-config.json` |
| 「主な更新点」（更新履歴）・冒頭のER図説明 | 定義書に直接書く（生成対象外） |

## 手順

### 1. マイグレーションを書く

```bash
cd supabase_schema
npm run migrate:new <name>
```

**カラムを追加・変更したら、同じマイグレーションに `COMMENT ON COLUMN` を必ず書く。**
これが定義書の「論理名」列になります。新規テーブルには `COMMENT ON TABLE` も書いてください。

```sql
ALTER TABLE public.orders ADD COLUMN coupon_code text;
COMMENT ON COLUMN public.orders.coupon_code IS 'クーポンコード';
```

### 2. ローカルDBに適用する

```bash
npm run start      # 未起動なら
npm run db:reset   # マイグレーションを最初から適用し直す
```

### 3. 定義書とER図を再生成する

```bash
npm run schema:docs     # .md と .mmd を生成し、続けて .svg へ変換する
```

個別に実行する場合:

| コマンド | 内容 |
|---|---|
| `npm run schema:docs:md` | 定義書と `.mmd` を生成 |
| `npm run schema:docs:svg` | `.mmd` を `.svg` に変換 |
| `npm run schema:docs:check` | 生成結果と現在のファイルを比較（書き込まない。CIと同じ） |

### 4. 新しいテーブルを足したときだけ config を更新する

`scripts/schema-doc-config.json` の `groups`（概要セクションの分類）と
`erDiagrams`（機能別ER図の構成）にテーブル名を追加します。
どちらにも属さないテーブルがあると生成が失敗するため、登録漏れは検出されます。

### 5. 更新履歴を書き足す

定義書末尾の「主な更新点」は人が書くセクションです。生成では触られません。

## よくあるエラー

### `COMMENT ON COLUMN が未設定のカラムがあります`

手順1の `COMMENT ON COLUMN` を書き忘れています。マイグレーションに追記して `npm run db:reset` からやり直してください。

### `config.groups の "xxx" が実スキーマに存在しません`

config に書いたテーブル名が実スキーマにありません。テーブル名の綴りか、config 側の消し忘れを確認してください。

### `以下のテーブルが scripts/schema-doc-config.json の groups に未登録です`

手順4を実施してください。

## CI

`.github/workflows/schema-docs.yml` が PR で `npm run schema:docs:check` を実行します。
マイグレーションを変えたのに生成物をコミットしていない、あるいは `COMMENT ON COLUMN` を
書き忘れている場合に落ちます。

SVG は mermaid がフォント幅を実測して座標に焼き込むため、Chromium とフォント構成が違えば
バイト列も変わります。コミット済みSVGとの比較は環境をまたぐと必ず不一致になるので、CI では比較しません。
図の内容は `.mmd` の一致で担保し、CI は変換が通ることの確認と、描画結果の成果物アップロードのみ行います。

そのため、**SVG の更新漏れは CI では検出できません**。`.mmd` だけコミットして `.svg` を忘れないよう、
再生成は個別コマンドではなく `npm run schema:docs` を使ってください。

## 対象外のテーブル

- `spatial_ref_sys`: PostGIS 拡張が所有するためマイグレーション管理外。`excludeTables` で除外しています

マテリアライズドビュー（`mv_products_catalog`）は定義書に出力され、テーブルと同じく
`COMMENT ON COLUMN` が必須です。ビュー自体の説明は `COMMENT ON MATERIALIZED VIEW` で付けます。
