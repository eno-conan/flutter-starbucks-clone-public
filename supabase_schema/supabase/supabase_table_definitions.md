# Supabaseプロジェクト テーブル定義書

プロジェクト: flutter-testingapp
作成日: 2025年7月20日
最終更新: 2026年8月20日

> ⚠️ **この定義書は実スキーマからの自動生成物です。**
> 「テーブル定義」以降のセクションを手で編集しても `npm run schema:docs` で上書きされます。
> カラムの論理名を直したいときは、マイグレーションの `COMMENT ON COLUMN` を修正してください。
> 手順: `.claude/rules/supabase/update-db-schema.md`
>
> 「主な更新点」と、この冒頭のER図の説明は生成対象外なので直接編集して構いません。

---

## 📊 ER図について

データベースの構造を視覚的に理解するため、**ER図（Entity Relationship Diagram）** を用意しています。

### 管理場所
```
supabase_schema/supabase/entity_relationship/
```

### ファイル一覧

#### 全体図
- **er_diagram_full.mmd / .svg** - 全テーブルの関連を表示した完全版ER図

#### 機能別ER図
- **er_diagram_user.mmd / .svg** - ユーザー・認証関連
- **er_diagram_product.mmd / .svg** - 商品・カテゴリ関連
- **er_diagram_order.mmd / .svg** - 注文・カート関連
- **er_diagram_star.mmd / .svg** - スター・リワード関連
- **er_diagram_eticket.mmd / .svg** - eチケット関連
- **er_diagram_store.mmd / .svg** - 店舗・スタッフ関連

### 表示方法

#### オンラインで確認
1. [Mermaid Live Editor](https://mermaid.live/) にアクセス
2. `.mmd`ファイルの内容をコピー＆ペースト

#### SVGファイルで確認
- `entity_relationship/`フォルダ内の`.svg`ファイルをブラウザで直接開く
- 各種ドキュメントツール（Notion、Confluence等）に埋め込み可能

詳細な使い方やER図の更新方法は、`entity_relationship/ER_README.md`を参照してください。

---

## テーブル定義

> ⚠️ このセクションは `npm run schema:docs` による自動生成です。直接編集しても次回生成時に上書きされます。
> 論理名（日本語のカラム名）はマイグレーションの `COMMENT ON COLUMN` が正です。

## campaign_settings

キャンペーンの期間・表示設定

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ |  | AUTO INCREMENT (campaign_settings_id_seq) |
| キャンペーン名 | campaign_name | varchar(100) |  |  | NOT NULL, UNIQUE制約 |
| 表示名 | display_name | varchar(200) |  |  |  |
| 開始日時 | start_date | timestamptz |  |  | NOT NULL |
| 終了日時 | end_date | timestamptz |  |  | NOT NULL |
| 有効フラグ | is_active | boolean |  |  | デフォルト: true |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**CHECK制約**: `CHECK ((start_date < end_date))`

---

## cards

ユーザーが保有するプリペイドカード

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  | デフォルト: gen_random_uuid() |
| カードID | card_id | text |  |  | NOT NULL, UNIQUE制約, CHECK制約: card_id ~ '^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}$'::text |
| ユーザーID | user_id | uuid |  | auth.users.id | NOT NULL, ON DELETE CASCADE |
| カード名 | card_name | text |  |  | NOT NULL |
| 画像URL | image_url | text |  |  |  |
| 残高 | balance | integer |  |  | デフォルト: 0, CHECK制約: balance >= 0 |
| メインカードフラグ | is_main | boolean |  |  | デフォルト: false, NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**インデックス**: `cards_user_id_is_main_key` (UNIQUE) / `idx_cards_user_id`

---

## carts

ユーザーごとのカート（1ユーザー1カート）

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ユーザーID | user_id | uuid | ○ | auth.users.id | ON DELETE CASCADE |
| 店舗番号 | store_number | bpchar(4) |  | stores.store_number | NOT NULL |
| 支払方法 | payment_method | text |  |  |  |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 利用区分 | usage | smallint |  |  | デフォルト: 1, NOT NULL, CHECK制約: usage = ANY (ARRAY[1, 2, 3]) |

**インデックス**: `idx_carts_store_number`

---

## carts_detail

カート明細

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ユーザーID | user_id | uuid | ○ | carts.user_id | ON DELETE CASCADE |
| 商品インデックス | item_index | integer | ○ |  |  |
| 商品ID | product_id | integer |  | products.product_id | NOT NULL |
| 温度タイプID | temperature_type_id | integer |  | temperature_types.temperature_type_id | NOT NULL |
| サイズID | size_id | integer |  | sizes.size_id | NOT NULL |
| 数量 | count | integer |  |  | NOT NULL, CHECK制約: count > 0 |
| 税抜小計 | subtotal_without_tax | integer |  |  | NOT NULL, CHECK制約: subtotal_without_tax >= 0 |

**主キー**: `(user_id, item_index)` の複合主キー

**インデックス**: `idx_carts_detail_size_id` / `idx_carts_detail_temperature_type_id`

---

## categories

商品カテゴリマスタ

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| カテゴリID | category_id | integer | ○ |  | AUTO INCREMENT (categories_category_id_seq) |
| カテゴリ名 | category_name | text |  |  | NOT NULL |
| 説明 | description | text |  |  |  |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

---

## e_tickets_promotions

プロモーション系eチケットの定義（割引率/割引額）

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ |  | AUTO INCREMENT (e_tickets_promotions_id_seq) |
| 短縮名 | short_name | text |  |  | NOT NULL |
| eチケット名 | name | text |  |  | NOT NULL |
| 画像URL | image_url | text |  |  |  |
| 割引タイプ | discount_type | text |  |  | NOT NULL |
| 割引値 | discount_value | integer |  |  | NOT NULL |
| 誕生月限定フラグ | is_birthday_month_only | boolean |  |  | デフォルト: false, NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

---

## e_tickets_special_offers

特別オファー系eチケットの定義（特別価格商品）

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ |  | AUTO INCREMENT (e_tickets_special_offers_id_seq) |
| 短縮名 | short_name | text |  |  | NOT NULL |
| eチケット名 | name | text |  |  | NOT NULL |
| 画像URL | image_url | text |  |  |  |
| 特別価格 | special_price | integer |  |  | NOT NULL |
| 対象SKU ID | target_sku_id | text |  |  | NOT NULL |
| 1注文あたりの最大数量 | max_quantity_per_order | integer |  |  | デフォルト: 1, NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

---

## email_check_rate_limits

メールアドレス重複チェックRPCのレート制限。service_role のみアクセス可

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  | デフォルト: gen_random_uuid() |
| IPハッシュ | ip_hash | text |  |  | NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**インデックス**: `email_check_rate_limits_ip_hash_created_at_idx`

---

## orders

注文。price_without_tax / price_with_tax は orders_detail の小計合計と一致する前提で、create_order_with_details が同一トランザクションで書き込む。この RPC を経由しない直接 INSERT はヘッダと明細の整合を壊すため使わないこと (Issue #938 D-3)

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  | デフォルト: gen_random_uuid() |
| 注文ID | order_id | varchar(32) |  |  | NOT NULL, UNIQUE制約 |
| ユーザーID | user_id | uuid |  | auth.users.id | ON DELETE SET NULL |
| 注文タイプ | order_type | smallint |  |  | NOT NULL, CHECK制約: order_type = ANY (ARRAY[1, 2]) |
| 受取番号 | pickup_number | text |  |  | NOT NULL |
| 税抜価格 | price_without_tax | integer |  |  | NOT NULL, CHECK制約: price_without_tax >= 0 |
| 税込価格 | price_with_tax | integer |  |  | NOT NULL |
| 支払方法 | payment_method | text |  |  | NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 提供ステータス | provided_status | provided_status_enum |  |  | デフォルト: 'pending', NOT NULL |
| 店舗番号 | store_number | bpchar(4) |  | stores.store_number | NOT NULL |
| 利用区分 | usage | smallint |  |  | デフォルト: 1, NOT NULL, CHECK制約: usage = ANY (ARRAY[1, 2, 3]) |
| 消費税率 | tax_rate | smallint |  |  | NOT NULL, CHECK制約: (tax_rate >= 0) AND (tax_rate <= 100) |

**CHECK制約**: `CHECK ((price_with_tax >= price_without_tax))`

**インデックス**: `idx_orders_store_number` / `idx_orders_user_id`

---

## orders_archive

注文履歴アーカイブ: 18ヶ月以上前のordersデータを保存。マーケティング分析用途。

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  |  |
| 注文ID | order_id | text |  |  | NOT NULL, UNIQUE制約 |
| ユーザーID | user_id | uuid |  |  | NOT NULL |
| 店舗番号 | store_number | bpchar(4) |  |  | NOT NULL |
| 利用区分 | usage | smallint |  |  | NOT NULL |
| 注文タイプ | order_type | smallint |  |  | NOT NULL |
| 受取番号 | pickup_number | text |  |  | NOT NULL |
| 税抜価格 | price_without_tax | integer |  |  | NOT NULL |
| 税込価格 | price_with_tax | integer |  |  | NOT NULL |
| 支払方法 | payment_method | text |  |  | NOT NULL |
| 提供ステータス | provided_status | provided_status_enum |  |  | デフォルト: 'pending', NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | NOT NULL |
| アーカイブ日時 | archived_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 消費税率 | tax_rate | smallint |  |  | NOT NULL |

**インデックス**: `idx_orders_archive_archived_at` / `idx_orders_archive_created_at` / `idx_orders_archive_user_id`

---

## orders_detail

注文明細。product_name / unit_price_without_tax は注文時点のスナップショットであり、products / product_sizes の改定で書き換えてはならない (Issue #938 D-1)

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  | デフォルト: uuid_generate_v4() |
| 注文ID | order_id | varchar(32) |  | orders.order_id | NOT NULL |
| ユーザーID | user_id | uuid |  | auth.users.id | ON DELETE SET NULL |
| 商品ID | product_id | integer |  | products.product_id | NOT NULL |
| 温度タイプID | temperature_type_id | integer |  | temperature_types.temperature_type_id | NOT NULL |
| サイズID | size_id | integer |  | sizes.size_id | NOT NULL |
| 数量 | count | integer |  |  | NOT NULL, CHECK制約: count > 0 |
| 税抜小計 | subtotal_without_tax | integer |  |  | NOT NULL, CHECK制約: subtotal_without_tax >= 0 |
| 商品名 | product_name | text |  |  | NOT NULL |
| 税抜単価 | unit_price_without_tax | integer |  |  | NOT NULL, CHECK制約: unit_price_without_tax >= 0 |

**CHECK制約**: `CHECK ((subtotal_without_tax = (unit_price_without_tax * count)))`

**インデックス**: `idx_orders_detail_order_id` / `idx_orders_detail_size_id` / `idx_orders_detail_temperature_type_id` / `idx_orders_detail_user_id`

---

## orders_detail_archive

注文詳細履歴アーカイブ: ordersと連動してアーカイブ。

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  |  |
| 注文ID | order_id | text |  |  |  |
| ユーザーID | user_id | uuid |  |  |  |
| 商品ID | product_id | integer |  |  |  |
| 温度タイプID | temperature_type_id | integer |  |  |  |
| サイズID | size_id | integer |  |  |  |
| 数量 | count | integer |  |  | NOT NULL |
| 税抜小計 | subtotal_without_tax | integer |  |  | NOT NULL |
| アーカイブ日時 | archived_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 商品名 | product_name | text |  |  |  |
| 税抜単価 | unit_price_without_tax | integer |  |  |  |

**インデックス**: `idx_orders_detail_archive_order_id`

---

## poc_realtime

Supabase Realtime 検証用のPoCテーブル。本番機能では使用しない（参照元は lib/poc/ のみ）。別スキーマへの隔離・削除は PoC 画面をアプリから外すときに合わせて判断する (Issue #938 E-5)

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  | デフォルト: gen_random_uuid() |
| ユーザーID | user_id | uuid |  | auth.users.id | NOT NULL, ON DELETE CASCADE |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

---

## pre_signup_users

本登録前の仮登録ユーザー

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  | デフォルト: gen_random_uuid() |
| トークン | token | text |  |  | NOT NULL, CHECK制約: char_length(token) = 32 |
| メールアドレス | email | text |  |  | NOT NULL, CHECK制約: char_length(email) <= 128, CHECK制約: email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 有効期限 | expires_at | timestamptz |  |  | NOT NULL |

**インデックス**: `pre_signup_users_token_idx` (UNIQUE)

---

## prefectures

都道府県マスタ

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ |  | AUTO INCREMENT (prefectures_id_seq) |
| 都道府県名 | name | text |  |  | NOT NULL |

---

## product_sizes

商品とサイズの関連（価格を保持）

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 商品ID | product_id | integer | ○ | products.product_id |  |
| サイズID | size_id | integer | ○ | sizes.size_id |  |
| 価格 | price | integer |  |  | NOT NULL, CHECK制約: price >= 0 |

**主キー**: `(product_id, size_id)` の複合主キー

---

## product_temperature_types

商品と温度タイプの関連

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 商品ID | product_id | integer | ○ | products.product_id |  |
| 温度タイプID | temperature_type_id | integer | ○ | temperature_types.temperature_type_id |  |

**主キー**: `(product_id, temperature_type_id)` の複合主キー

**インデックス**: `idx_product_temperature_types_temperature_type_id`

---

## products

商品マスタ

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 商品ID | product_id | integer | ○ |  | AUTO INCREMENT (products_product_id_seq) |
| 商品名 | product_name | text |  |  | NOT NULL |
| カテゴリID | category_id | integer |  | categories.category_id |  |
| 説明 | description | text |  |  |  |
| 有効フラグ | is_active | boolean |  |  | デフォルト: true |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 商品画像パス | product_image_path | varchar(255) |  |  | デフォルト: 'https://placehold.co/150x150', NOT NULL |
| 表示順 | display_order | integer |  |  | デフォルト: 999 |
| 販売タイプ | sale_type | sale_type_enum |  |  | デフォルト: 'regular' |

---

## sizes

サイズマスタ

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| サイズID | size_id | integer | ○ |  | AUTO INCREMENT (sizes_size_id_seq) |
| サイズ名 | size_name | text |  |  | NOT NULL |
| サイズ説明 | size_description | text |  |  |  |

---

## staff

スタッフマスタ

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| スタッフ番号 | staff_number | varchar(50) | ○ |  |  |
| スタッフ名 | staff_name | varchar(100) |  |  | NOT NULL |
| メールアドレス | email | varchar(255) |  |  |  |
| 電話番号 | phone | varchar(20) |  |  |  |
| 雇用形態 | employment_type | varchar(20) |  |  |  |
| 入社日 | hire_date | date |  |  |  |
| 退職日 | termination_date | date |  |  |  |
| 有効フラグ | is_active | boolean |  |  | デフォルト: true |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

---

## staff_schedules

スタッフの日次シフトスケジュール

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | bigint | ○ |  | AUTO INCREMENT (staff_schedules_id_seq) |
| 日付 | date | date |  |  | NOT NULL, UNIQUE制約: (date, staff_number) |
| スタッフ番号 | staff_number | varchar(50) |  | staff.staff_number | NOT NULL, UNIQUE制約: (date, staff_number) |
| 店舗番号 | store_number | bpchar(4) |  | stores.store_number |  |
| 第1時間帯勤務 | period_1 | boolean |  |  | デフォルト: false |
| 第2時間帯勤務 | period_2 | boolean |  |  | デフォルト: false |
| 第3時間帯勤務 | period_3 | boolean |  |  | デフォルト: false |
| 第4時間帯勤務 | period_4 | boolean |  |  | デフォルト: false |
| 第5時間帯勤務 | period_5 | boolean |  |  | デフォルト: false |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**インデックス**: `idx_staff_schedules_staff` / `idx_staff_schedules_store_number`

---

## star_acquisitions

スター獲得履歴

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  | デフォルト: gen_random_uuid() |
| ユーザーID | user_id | uuid |  | auth.users.id | ON DELETE SET NULL |
| 注文ID | order_id | varchar(32) |  | orders.order_id | NOT NULL, UNIQUE制約: (order_id, category) |
| カテゴリ | category | smallint |  |  | NOT NULL, UNIQUE制約: (order_id, category), CHECK制約: category = ANY (ARRAY[1, 2, 3]) |
| 獲得ポイント | acquired_points | numeric(10,1) |  |  | NOT NULL, CHECK制約: acquired_points >= (0)::numeric |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**インデックス**: `idx_star_acquisitions_user_id`

---

## star_acquisitions_archive

スター取得履歴アーカイブ: 18ヶ月以上前のstar_acquisitionsデータを保存。

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  |  |
| ユーザーID | user_id | uuid |  |  | NOT NULL |
| 注文ID | order_id | text |  |  | NOT NULL |
| カテゴリ | category | smallint |  |  | NOT NULL |
| 獲得ポイント | acquired_points | numeric(10,1) |  |  | NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | NOT NULL |
| アーカイブ日時 | archived_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**インデックス**: `idx_star_acquisitions_archive_created_at` / `idx_star_acquisitions_archive_user_id`

---

## star_aggregations

ユーザー・年月ごとのスター集計

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ユーザーID | user_id | uuid | ○ | auth.users.id | ON DELETE CASCADE |
| 対象年月 | target_year_month | bpchar(6) | ○ |  |  |
| 合計ポイント | total_points | numeric(10,1) |  |  | デフォルト: 0, NOT NULL, CHECK制約: total_points >= (0)::numeric |
| 有効期限 | expiration_datetime | timestamptz |  |  | NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 期限切れフラグ | expiration_flag | boolean |  |  | デフォルト: false, NOT NULL |

**主キー**: `(user_id, target_year_month)` の複合主キー

---

## star_rewards_exchange_items

スター交換商品マスタ

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ |  | AUTO INCREMENT (star_rewards_exchange_items_id_seq) |
| 短縮名 | short_name | text |  |  | NOT NULL |
| 商品名 | name | text |  |  | NOT NULL |
| 画像URL | image_url | text |  |  |  |
| 必要ポイント | points | integer |  |  | NOT NULL |

---

## star_usage

スター使用履歴

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  | デフォルト: gen_random_uuid() |
| ユーザーID | user_id | uuid |  | auth.users.id | ON DELETE SET NULL |
| 注文ID | order_id | varchar(32) |  | orders.order_id |  |
| 交換商品ID | exchange_item_id | integer |  | star_rewards_exchange_items.id |  |
| 使用ポイント | point_used | numeric(10,1) |  |  | NOT NULL, CHECK制約: point_used >= (0)::numeric |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**CHECK制約**: `CHECK (((order_id IS NOT NULL) OR (exchange_item_id IS NOT NULL)))`

**インデックス**: `idx_star_usage_user_id`

---

## star_usage_archive

スター使用履歴アーカイブ: 18ヶ月以上前のstar_usageデータを保存。

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  |  |
| ユーザーID | user_id | uuid |  |  | NOT NULL |
| 注文ID | order_id | varchar(32) |  |  |  |
| 交換商品ID | exchange_item_id | integer |  |  |  |
| 使用ポイント | point_used | numeric(10,1) |  |  | NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | NOT NULL |
| アーカイブ日時 | archived_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**インデックス**: `idx_star_usage_archive_created_at` / `idx_star_usage_archive_user_id`

---

## store_profiles

店舗の詳細プロフィール

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ |  | AUTO INCREMENT (store_profiles_id_seq) |
| 店舗番号 | store_number | bpchar(4) |  | stores.store_number | NOT NULL |
| ユーザーID | user_id | uuid |  | auth.users.id | NOT NULL, UNIQUE制約, ON DELETE CASCADE |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**インデックス**: `idx_store_profiles_store_number`

---

## stores

店舗マスタ

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ |  | AUTO INCREMENT (stores_id_seq) |
| 店舗番号 | store_number | bpchar(4) |  |  | NOT NULL, UNIQUE制約 |
| 店舗名 | store_name | text |  |  | NOT NULL |
| 都道府県ID | prefecture_id | integer |  | prefectures.id | NOT NULL |
| 住所 | address | text |  |  | NOT NULL |
| オープン日 | opening_date | date |  |  | NOT NULL |
| 閉店日 | closing_date | date |  |  |  |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: CURRENT_TIMESTAMP, NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: CURRENT_TIMESTAMP, NOT NULL |
| 閉店時間 | closing_time | time |  |  | デフォルト: '21:00:00', NOT NULL |
| 開店時間 | opening_time | time |  |  | デフォルト: '09:00:00', NOT NULL |
| 緯度 | latitude | float8 |  |  | NOT NULL, CHECK制約: (latitude >= ('-90'::integer)::double precision) AND (latitude <= (90)::double precision) |
| 経度 | longitude | float8 |  |  | NOT NULL, CHECK制約: (longitude >= ('-180'::integer)::double precision) AND (longitude <= (180)::double precision) |
| ドライブスルー利用可能 | is_drive_thru_available | boolean |  |  | デフォルト: false, NOT NULL |

**CHECK制約**: `CHECK ((opening_time < closing_time))`

**インデックス**: `idx_stores_prefecture_id`

---

## temperature_types

温度タイプ（ホット/アイス等）マスタ

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 温度タイプID | temperature_type_id | integer | ○ |  | AUTO INCREMENT (temperature_types_temperature_type_id_seq) |
| タイプ名 | type_name | text |  |  | NOT NULL |

---

## user_fcm_tokens

ユーザーの端末ごとのFCMトークン

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| FCMトークン | fcm_token | text |  |  |  |
| 通知設定 | is_notify | boolean |  |  | デフォルト: false, NOT NULL |
| ユーザーID | user_id | uuid | ○ | auth.users.id | ON DELETE CASCADE |
| デバイスID | device_id | text | ○ |  |  |
| デバイス名 | device_name | text |  |  |  |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**主キー**: `(user_id, device_id)` の複合主キー

---

## user_mail_settings

ユーザーのメール受信設定

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  | デフォルト: uuid_generate_v4() |
| ユーザーID | user_id | uuid |  | auth.users.id | NOT NULL, UNIQUE制約, ON DELETE CASCADE |
| リワード関連メール送信設定 | is_send_related_rewards | boolean |  |  | デフォルト: false, NOT NULL |
| 商品先行告知メール送信設定 | is_send_advance_product_announce | boolean |  |  | デフォルト: false, NOT NULL |
| HTMLメール設定 | is_html_mail | boolean |  |  | デフォルト: true, NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

---

## user_nickname

ユーザーのニックネーム

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ユーザーID | user_id | uuid | ○ | auth.users.id | ON DELETE CASCADE |
| ニックネーム | nick_name | text |  |  | NOT NULL |

---

## user_profile_details

ユーザーのプロフィール詳細

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ |  | デフォルト: uuid_generate_v4() |
| ユーザーID | user_id | uuid |  | auth.users.id | NOT NULL, UNIQUE制約, ON DELETE CASCADE |
| 生年月日 | birthday | date |  |  |  |
| 性別 | sex | integer |  |  | CHECK制約: (sex IS NULL) OR (sex = ANY (ARRAY[0, 1, 2, 3])) |
| 電話番号 | tele_num | text |  |  |  |
| 郵便番号 | postal_code | text |  |  |  |
| 都道府県ID | prefecture_id | integer |  | prefectures.id |  |
| 住所1 | address1 | text |  |  |  |
| 住所2 | address2 | text |  |  |  |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |

**インデックス**: `idx_user_profile_details_prefecture_id`

---

## user_tickets

ユーザーが保有するeチケットの実体

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ |  | AUTO INCREMENT (user_tickets_id_seq) |
| ユーザーID | user_id | uuid |  | auth.users.id | NOT NULL, ON DELETE CASCADE |
| チケットタイプ | ticket_type | text |  |  | NOT NULL |
| 定義ID | definition_id | integer |  |  | NOT NULL |
| 有効期限 | expired_at | timestamptz |  |  | NOT NULL |
| 利用済フラグ | is_used | boolean |  |  | デフォルト: false, NOT NULL |
| 作成日時 | created_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz |  |  | デフォルト: now(), NOT NULL |
| 利用日時 | used_at | timestamptz |  |  |  |

**インデックス**: `idx_user_tickets_user_id`

---

## マテリアライズドビュー (Materialized Views)

## mv_products_catalog

商品カタログの結合済みビュー。products / categories / product_sizes / sizes / product_temperature_types / temperature_types を JOIN した読み取り専用スナップショット（更新手順は mv_products_catalog_guide.md）

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 商品ID | product_id | integer |  |  |  |
| 商品名 | product_name | text |  |  |  |
| カテゴリID | category_id | integer |  |  |  |
| カテゴリ名 | category_name | text |  |  |  |
| 説明 | description | text |  |  |  |
| 商品画像パス | product_image_path | varchar(255) |  |  |  |
| 販売タイプ | sale_type | sale_type_enum |  |  |  |
| 表示順 | display_order | integer |  |  |  |
| サイズID | size_id | integer |  |  |  |
| サイズ名 | size_name | text |  |  |  |
| 価格 | price | integer |  |  |  |
| 温度タイプID | temperature_type_id | integer |  |  |  |
| 温度タイプ名 | temperature_type_name | text |  |  |  |

**インデックス**: `idx_mv_products_catalog_unique` (UNIQUE)

---

## テーブル概要

### ユーザー管理

- `user_profile_details`: ユーザーのプロフィール詳細
- `user_mail_settings`: ユーザーのメール受信設定
- `user_nickname`: ユーザーのニックネーム
- `user_fcm_tokens`: ユーザーの端末ごとのFCMトークン
- `pre_signup_users`: 本登録前の仮登録ユーザー

### 商品・カテゴリ管理

- `products`: 商品マスタ
- `categories`: 商品カテゴリマスタ
- `sizes`: サイズマスタ
- `temperature_types`: 温度タイプ（ホット/アイス等）マスタ
- `product_sizes`: 商品とサイズの関連（価格を保持）
- `product_temperature_types`: 商品と温度タイプの関連
- `mv_products_catalog` *(Materialized View)*: 商品カタログの結合済みビュー。products / categories / product_sizes / sizes / product_temperature_types / temperature_types を JOIN した読み取り専用スナップショット（更新手順は mv_products_catalog_guide.md）

### 注文・カート機能

- `orders`: 注文。price_without_tax / price_with_tax は orders_detail の小計合計と一致する前提で、create_order_with_details が同一トランザクションで書き込む。この RPC を経由しない直接 INSERT はヘッダと明細の整合を壊すため使わないこと (Issue #938 D-3)
- `orders_detail`: 注文明細。product_name / unit_price_without_tax は注文時点のスナップショットであり、products / product_sizes の改定で書き換えてはならない (Issue #938 D-1)
- `carts`: ユーザーごとのカート（1ユーザー1カート）
- `carts_detail`: カート明細

### 店舗管理

- `stores`: 店舗マスタ
- `store_profiles`: 店舗の詳細プロフィール
- `prefectures`: 都道府県マスタ

### スタッフ・シフト管理

- `staff`: スタッフマスタ
- `staff_schedules`: スタッフの日次シフトスケジュール

### ポイント・リワード機能

- `star_acquisitions`: スター獲得履歴
- `star_aggregations`: ユーザー・年月ごとのスター集計
- `star_usage`: スター使用履歴
- `star_rewards_exchange_items`: スター交換商品マスタ

### eチケット機能

- `e_tickets_promotions`: プロモーション系eチケットの定義（割引率/割引額）
- `e_tickets_special_offers`: 特別オファー系eチケットの定義（特別価格商品）
- `user_tickets`: ユーザーが保有するeチケットの実体

### 決済・カード機能

- `cards`: ユーザーが保有するプリペイドカード

### キャンペーン

- `campaign_settings`: キャンペーンの期間・表示設定

### アーカイブ（18ヶ月経過データの退避先）

- `orders_archive`: 注文履歴アーカイブ: 18ヶ月以上前のordersデータを保存。マーケティング分析用途。
- `orders_detail_archive`: 注文詳細履歴アーカイブ: ordersと連動してアーカイブ。
- `star_acquisitions_archive`: スター取得履歴アーカイブ: 18ヶ月以上前のstar_acquisitionsデータを保存。
- `star_usage_archive`: スター使用履歴アーカイブ: 18ヶ月以上前のstar_usageデータを保存。

> 退避・削除の運用手順は `data_archive_guide.md` / `partitioning_archiving_guide.md` を参照

### その他

- `email_check_rate_limits`: メールアドレス重複チェックRPCのレート制限。service_role のみアクセス可
- `poc_realtime`: Supabase Realtime 検証用のPoCテーブル。本番機能では使用しない（参照元は lib/poc/ のみ）。別スキーマへの隔離・削除は PoC 画面をアプリから外すときに合わせて判断する (Issue #938 E-5)

合計35テーブルとマテリアライズドビュー1件で構成されています。

## 主な更新点

### 2026年8月20日
1. **旧テーブル `user_profiles` を削除**（20260820000001）:
   - FCMトークン保持用の旧テーブル。`user_fcm_tokens` へ移行済みでアプリからは未使用
   - リモートDBではマイグレーション外で既に削除されており、`npm run db:push` が
     20260819100000 の `COMMENT ON TABLE public.user_profiles` で失敗していた
   - 正式に `DROP TABLE` してローカル・リモート双方のスキーマを一致させた
   - 合わせて 20260819100000 から当該 COMMENT 文と `schema-doc-config.json` の登録を削除
2. **整合性・一貫性の改善 Step 1**（20260820011334 / Issue #938 のDB設計レビュー）:
   - **重複インデックスの削除**: `idx_orders_order_id` は UNIQUE 制約由来の
     `orders_order_id_key` と完全に同等だったため削除
   - **`prefectures` の RLS を有効化**: public スキーマで唯一 RLS が無効だった。
     他のマスタと同じ read-only ポリシー `read_only_prefectures` を追加
   - **`orders_detail` の外部キー列に NOT NULL**: `order_id` / `user_id` /
     `product_id` / `temperature_type_id` / `size_id`。孤児明細を許容していた
   - **スター二重付与の防止**: `star_acquisitions` に UNIQUE `(order_id, category)` を追加。
     副次効果として FK 列 `order_id` の索引も復活する
   - **メインカードの一意性**: `cards` に部分ユニークインデックス
     `cards_user_id_is_main_key`（`WHERE is_main = 1`）を追加
   - **金額・数量・座標の CHECK 制約を13件追加**: 残高・注文金額（税込 ≧ 税抜）・
     明細数量（> 0）・小計・商品価格・スターポイント・緯度経度の範囲
   - **`updated_at` 自動更新トリガを10テーブルに追加**: `campaign_settings` / `carts` /
     `categories` / `products` / `star_acquisitions` / `star_aggregations` /
     `store_profiles` / `stores` / `user_fcm_tokens` / `user_tickets`。
     関数は `update_updated_at_column()` に統一（既存トリガの張り替えは行わない）。
     アーカイブ3テーブルは退避元の `updated_at` を保持する必要があるため意図的に対象外
   - 適用前にローカル実データで違反ゼロを確認（18項目）。リモート適用前にも同じ確認が必要
3. **型・フラグ表現の統一と参照整合性の回復 Step 2**（20260820020409 / Issue #938 のDB設計レビュー）:
   - **`provided_status` を enum 化**: text の `'0'`/`'1'`/`'2'`/`'99'` を
     `provided_status_enum`（`pending` / `preparing` / `provided` / `cancelled`）へ。
     数値の意味を文字列で持っていたためソート・比較が文字列順になっていた。
     `orders_archive` も同じ型に揃え、`archive_old_orders` の
     `INSERT ... SELECT` からキャストを不要にした（レビュー G-5 の型ドリフト解消）。
     参照する RPC（`get_user_orders` / `get_store_wait_times`）も追従
   - **真偽値を boolean に統一**: 同じ「真偽」を integer / smallint / bpchar(1) の
     3通りで表現していた `cards.is_main` / `user_fcm_tokens.is_notify` /
     `user_mail_settings` の3列 / `star_aggregations.expiration_flag` /
     `stores.is_drive_thru_available`。
     `cards_user_id_is_main_key` は `WHERE is_main`（boolean）で再作成
   - **型不整合に起因する不具合を解消**: `stores.is_drive_thru_available` が bpchar を
     返すためアプリ側の `== 1`（int 比較）が常に false になっていた
   - **参照整合性の回復**: `carts_detail.user_id` の FK を `auth.users` から `carts` へ
     張り替え（親不在の明細を許容していた）、`star_usage.order_id` を varchar(32) にして
     `orders` への FK と「`order_id` / `exchange_item_id` のどちらか必須」の CHECK を追加、
     `staff_schedules.store_number` を character(4) にして `stores` への FK と索引を追加
   - **`archive_old_orders` の退避対象に `star_usage` を追加**: 上記 FK により、
     退避漏れの `star_usage` が残っていると `orders` の DELETE が失敗するため。
     既存の `star_acquisitions` と同じ扱いに揃えた
   - **`user_profile_details.birthday` を date へ**: アプリの `'YYYYMMDD'` 文字列保存をやめ、
     誕生月判定を書式非依存にした。`sex` にも値域 CHECK（0〜3）を追加
   - アプリ改修（`lib/constants/provided_status.dart` の新設ほか12ファイル）と
     `seed.sql` の更新を伴うため、マイグレーション単独では適用できない
   - 適用前チェックは `snippets/preflight_step2.sql`（28項目）。
     Step 1 と違い「エラーにならず値が静かに変換・NULL 化される」変換を含むため、
     BLOCKED / WARN / INFO を区別して出力する
4. **履歴の保全・ライフサイクル整備 Step 3**（20260820100001〜100004 / Issue #938 のDB設計レビュー C・D・E）:
   - **期間・座標の制約**（レビュー C の残り）: `stores` に
     `stores_opening_before_closing`、`campaign_settings` に
     `campaign_settings_start_before_end` を追加。
     `stores.latitude` / `longitude` の `DEFAULT 0.0` を削除した。
     (0, 0) はギニア湾沖の実在座標で「未設定」と区別できず、距離検索に紛れ込んでいた
   - **注文明細のスナップショット**（D-1）: `orders_detail` に `product_name` /
     `unit_price_without_tax` を追加。マスタの価格改定・商品名変更・非公開化が
     過去の注文表示に波及しなくなる。`subtotal_without_tax = unit_price × count` を
     CHECK で固定し、`orders_detail_archive` にも同じ列を追加した
   - **注文の税率**（D-2）: `orders` / `orders_archive` に `tax_rate`（整数パーセント）を追加。
     これまで税額は税込・税抜の差分でしか出せず、税率改定をまたぐと再計算できなかった。
     既存行は差分から復元し、`create_order_with_details` は `p_tax_rate` を受け取る
     （未指定の旧クライアントからの呼び出しでも差分から復元して動く）
   - **ヘッダと明細の整合を明記**（D-3）: `orders` / `orders_detail` の
     `COMMENT ON TABLE` に、`create_order_with_details` が同一トランザクションで
     両方を書く前提を残した
   - **履歴参照 RPC をスナップショット基準へ**: `get_user_orders` / `get_store_order_list`
     から `products` への JOIN を外した
   - **退会時の削除ポリシー**（E-1）: 個人設定・保有物（`cards` / `carts` /
     `user_fcm_tokens` / `user_tickets` / `store_profiles` / `star_aggregations`）は
     `ON DELETE CASCADE`、取引履歴（`orders` / `orders_detail` / `star_acquisitions` /
     `star_usage`）は `ON DELETE SET NULL` で行を残して匿名化する。
     そのため取引履歴4テーブルの `user_id` は nullable になった
     （Step 1 で入れた `orders_detail.user_id` の NOT NULL は意図的に緩めている。
     孤児明細の防止は `order_id` → `orders` の FK が担い、
     作成時の欠落は `create_order_with_details` / `handle_star_acquisition` が弾く）
   - **`created_at` / `updated_at` の NOT NULL 統一**（E-3）: 初期に作られた8テーブル
     （`campaign_settings` / `categories` / `products` / `staff` / `staff_schedules` /
     `store_profiles` / `stores` / `user_fcm_tokens`）
   - **`poc_realtime` の位置づけを明記**（E-5）: `lib/poc/` の画面が稼働中のため
     別スキーマへの隔離・削除は行わず、判断の前提を `COMMENT ON TABLE` に残した
   - **期限切れ行のクリーンアップ**（E-7）: `cleanup_expired_pre_signup_users` /
     `cleanup_email_check_rate_limits` を追加し、`cron/archive_data.sql` に日次ジョブを登録
   - アプリ改修（税率の受け渡し・単価の送信）を伴うため、マイグレーション単独では適用できない
   - 適用前チェックは `snippets/preflight_step3.sql`（19項目）
   - **未対応**: E-6（`pre_signup_users.token` の平文保存）は、トークン生成と
     メール送信を Edge Function 側へ移す再設計と Dashboard の DB Webhook 変更を伴うため
     別 Issue とした

### 2026年8月19日（その2: 自動生成への移行）
1. **定義書とER図を実スキーマからの自動生成に移行**:
   - `npm run schema:docs` でローカルDBを読み、`.md` / `.mmd` / `.svg` を生成する
   - 「テーブル定義」以降は生成物。「主な更新点」とER図の説明は引き続き手書き
   - CI (`.github/workflows/schema-docs.yml`) が PR で生成物の追従漏れを検出する
2. **論理名の正を `COMMENT ON COLUMN` へ移行**（20260819100000）:
   - 既存248カラムに COMMENT を付与。以降はマイグレーションに併記する運用
3. **移行時に判明した定義書の誤りを修正**:
   - `carts.price_without_tax` / `price_with_tax`: 20250720065510 で削除済みなのに残存していた
   - `products.sale_type` / `display_order`: 20250812133032 で追加されたのに未記載だった
   - `user_tickets.used_at`: 未記載だった

### 2026年8月19日
1. **未反映だったテーブルを追加（定義書の棚卸し）**:
   - `user_profiles`（20250406013719）: 旧FCMトークンテーブル。未使用である旨を明記
   - `campaign_settings`（20250906103245）: キャンペーン設定
   - `user_nickname`（20250924120556）: ユーザーニックネーム
   - `poc_realtime`（20260111054436）: Realtime検証用PoC
   - `email_check_rate_limits`（20260223100001）: メール重複チェックのレート制限
   - `orders_archive` / `orders_detail_archive` / `star_acquisitions_archive` / `star_usage_archive`（20260319000001）: アーカイブ4テーブル
2. **`user_fcm_tokens` のマルチデバイス対応を反映**（20260314000001 / 20260819000001）:
   - `device_id` / `device_name` / `created_at` / `updated_at` を追加
   - 主キーを `user_id` 単独から複合主キー `(user_id, device_id)` に変更
   - `device_id` のグローバルユニーク制約は 20260819000001 で削除
3. **実在しないテーブルの記載を削除**:
   - `purchase_history`: `CREATE TABLE` が存在せず、`Tables` 定数にも未定義。
     購入履歴は `orders` から取得する方針のため、テーブル自体を作成していない
   - `sample`: マイグレーション・アプリコードのいずれからも参照なし
   - ※ ER図（`entity_relationship/`）には両者が残存しているため、別途再生成が必要
4. **ER図の管理場所パスを修正**: `supabase_schema/supabase/er/` → `supabase_schema/supabase/entity_relationship/`

### 2026年3月10日
1. **マテリアライズドビューの追加**:
   - `mv_products_catalog`: 商品カタログ結合ビューの定義を追記
   - 更新手順を `mv_products_catalog_guide.md` として別ファイルに整理

### 2026年2月15日
1. **スタッフ・シフト管理機能の追加（Issue #538対応）**:
   - `staff`: スタッフマスタテーブル追加
   - `staff_schedules`: スタッフシフトスケジュールテーブル追加
2. **待ち時間算出機能の土台**:
   - スタッフ情報と日次シフトスケジュールを管理
   - 時間帯別（period_1 ~ period_5）の勤務状況を記録
   - 店舗別・日付別のスタッフ配置状況を追跡可能

### 2026年1月5日
1. **eチケット機能の追加（Issue #495対応）**:
   - `e_tickets_promotions`: プロモーション系eチケットマスタテーブル追加
   - `e_tickets_special_offers`: 特別オファー系eチケットマスタテーブル追加
   - `user_tickets`: ユーザー保有eチケット実体テーブル追加
2. **eチケットの種類**:
   - STAR_REWARD: スターポイント交換チケット（既存のstar_rewards_exchange_itemsと紐づく）
   - PROMOTION: プロモーションチケット（割引率/割引額）
   - SPECIAL_OFFER: 特別オファーチケット（特別価格、例: One More Coffee）
3. **関連RPC関数の追加**:
   - `get_user_available_tickets`: ログインユーザーの未使用eチケット取得
   - `get_user_used_tickets`: ログインユーザーの使用済eチケット取得

### 2025年7月20日
1. **制約の追加**: 各テーブルでNOT NULL制約、CHECK制約、UNIQUE制約を明記
2. **デフォルト値の詳細化**: より具体的なデフォルト値を記載
3. **バリデーション制約**:
   - cardsテーブルのcard_idに正規表現バリデーション
   - pre_signup_usersテーブルのtokenとemailに文字数制約
   - ordersテーブルの各種ステータスに値制約
   - storesテーブルのドライブスルー可否に値制約
4. **主キー構造の更新**: cartsテーブルでuser_idが単一主キーに変更

合計37テーブル（うちアーカイブ4テーブル）とマテリアライズドビュー1件で構成されており、カフェ・コーヒーショップアプリの主要機能をカバーする包括的なデータベース設計となっています。