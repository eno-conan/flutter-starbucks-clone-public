# Supabaseプロジェクト テーブル定義書

プロジェクト: flutter-testingapp
作成日: 2025年7月20日
最終更新: 2026年2月15日

---

## 📊 ER図について

データベースの構造を視覚的に理解するため、**ER図（Entity Relationship Diagram）** を用意しています。

### 管理場所
```
supabase_schema/supabase/er/
```

### ファイル一覧

#### 全体図
- **er_diagram_full.mmd / .svg** - 全28テーブルの関連を表示した完全版ER図

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
- `er/`フォルダ内の`.svg`ファイルをブラウザで直接開く
- 各種ドキュメントツール（Notion、Confluence等）に埋め込み可能

詳細な使い方やER図の更新方法は、`er/ER_README.md`を参照してください。

---

## テーブル定義

### spatial_ref_sys

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 空間参照システムID | srid | integer | ○ | | CHECK制約: srid > 0 AND srid <= 998999 |
| 認証機関名 | auth_name | varchar | | | |
| 認証機関SRID | auth_srid | integer | | | |
| 空間参照テキスト | srtext | varchar | | | |
| Proj4テキスト | proj4text | varchar | | | |

## cards

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ | | デフォルト: gen_random_uuid() |
| カードID | card_id | text | | | UNIQUE制約, CHECK制約: 正規表現パターン '^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}$' |
| ユーザーID | user_id | uuid | | auth.users.id | NOT NULL |
| カード名 | card_name | text | | | NOT NULL |
| 画像URL | image_url | text | | | |
| 残高 | balance | integer | | | デフォルト: 0 |
| メインカードフラグ | is_main | integer | | | デフォルト: 0 |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now(), NOT NULL |

## carts

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ユーザーID | user_id | uuid | ○ | auth.users.id | |
| 店舗番号 | store_number | bpchar | | stores.store_number | NOT NULL |
| 税抜価格 | price_without_tax | integer | | | |
| 税込価格 | price_with_tax | integer | | | |
| 支払方法 | payment_method | text | | | |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 利用区分 | usage | smallint | | | |

## carts_detail

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ユーザーID | user_id | uuid | ○ | auth.users.id | |
| 商品インデックス | item_index | integer | ○ | | |
| 商品ID | product_id | integer | | | NOT NULL |
| 温度タイプID | temperature_type_id | integer | | | NOT NULL |
| サイズID | size_id | integer | | | NOT NULL |
| 数量 | count | integer | | | NOT NULL |
| 税抜小計 | subtotal_without_tax | integer | | | NOT NULL |

## categories

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| カテゴリID | category_id | integer | ○ | | AUTO INCREMENT |
| カテゴリ名 | category_name | text | | | NOT NULL |
| 説明 | description | text | | | |
| 作成日時 | created_at | timestamptz | | | デフォルト: now() |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now() |

## e_tickets_promotions

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ | | AUTO INCREMENT |
| 短縮名 | short_name | text | | | NOT NULL |
| eチケット名 | name | text | | | NOT NULL |
| 画像URL | image_url | text | | | |
| 割引タイプ | discount_type | text | | | NOT NULL, 値: 'percentage'（割引率）または 'amount'（割引額） |
| 割引値 | discount_value | integer | | | NOT NULL, discount_typeがpercentageの場合はパーセント値、amountの場合は金額 |
| 誕生月限定フラグ | is_birthday_month_only | boolean | | | デフォルト: false, NOT NULL |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |

## e_tickets_special_offers

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ | | AUTO INCREMENT |
| 短縮名 | short_name | text | | | NOT NULL |
| eチケット名 | name | text | | | NOT NULL, 例: 'One More Coffee' |
| 画像URL | image_url | text | | | |
| 特別価格 | special_price | integer | | | NOT NULL, このチケットを使用した場合の商品価格 |
| 対象SKU ID | target_sku_id | text | | | NOT NULL, 対象商品のSKU ID |
| 1注文あたりの最大数量 | max_quantity_per_order | integer | | | デフォルト: 1, NOT NULL |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |

## orders

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ | | デフォルト: gen_random_uuid() |
| 注文ID | order_id | varchar | | | UNIQUE制約, NOT NULL |
| ユーザーID | user_id | uuid | | auth.users.id | NOT NULL |
| 注文タイプ | order_type | smallint | | | NOT NULL, CHECK制約: order_type IN (1, 2) 店頭注文 / モバイルオーダー|
| 受取番号 | pickup_number | text | | | NOT NULL |
| 税抜価格 | price_without_tax | integer | | | NOT NULL |
| 税込価格 | price_with_tax | integer | | | NOT NULL |
| 支払方法 | payment_method | text | | | NOT NULL |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 提供ステータス | provided_status | text | | | デフォルト: '0', CHECK制約: provided_status IN ('0', '1', '2', '99') |
| 店舗番号 | store_number | bpchar | | stores.store_number | NOT NULL |
| 利用区分 | usage | smallint | | | デフォルト: 1, CHECK制約: usage IN (1, 2, 3) 店内飲食 / 持ち帰り / ドライブスルー|

## orders_detail

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ | | デフォルト: uuid_generate_v4() |
| 注文ID | order_id | varchar | | orders.order_id | |
| ユーザーID | user_id | uuid | | auth.users.id | |
| 商品ID | product_id | integer | | products.product_id | |
| 温度タイプID | temperature_type_id | integer | | temperature_types.temperature_type_id | |
| サイズID | size_id | integer | | sizes.size_id | |
| 数量 | count | integer | | | NOT NULL |
| 税抜小計 | subtotal_without_tax | integer | | | NOT NULL |

## pre_signup_users

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ | | デフォルト: gen_random_uuid() |
| トークン | token | text | | | NOT NULL, CHECK制約: char_length(token) = 32 |
| メールアドレス | email | text | | | NOT NULL, CHECK制約: char_length(email) <= 128 |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 有効期限 | expires_at | timestamptz | | | NOT NULL |

## prefectures

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ | | AUTO INCREMENT |
| 都道府県名 | name | text | | | NOT NULL |

## product_sizes

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 商品ID | product_id | integer | ○ | products.product_id | |
| サイズID | size_id | integer | ○ | sizes.size_id | |
| 価格 | price | integer | | | NOT NULL |

## product_temperature_types

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 商品ID | product_id | integer | ○ | products.product_id | |
| 温度タイプID | temperature_type_id | integer | ○ | temperature_types.temperature_type_id | |

## products

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 商品ID | product_id | integer | ○ | | AUTO INCREMENT |
| 商品名 | product_name | text | | | NOT NULL |
| カテゴリID | category_id | integer | | categories.category_id | |
| 説明 | description | text | | | |
| 有効フラグ | is_active | boolean | | | デフォルト: true |
| 作成日時 | created_at | timestamptz | | | デフォルト: now() |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now() |
| 商品画像パス | product_image_path | varchar | | | デフォルト: 'https://placehold.co/150x150', NOT NULL |

## sizes

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| サイズID | size_id | integer | ○ | | AUTO INCREMENT |
| サイズ名 | size_name | text | | | NOT NULL |
| サイズ説明 | size_description | text | | | |

## star_acquisitions

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ | | デフォルト: gen_random_uuid() |
| ユーザーID | user_id | uuid | | auth.users.id | NOT NULL |
| 注文ID | order_id | varchar | | orders.order_id | NOT NULL |
| カテゴリ | category | smallint | | | NOT NULL, CHECK制約: category IN (1, 2, 3) |
| 獲得ポイント | acquired_points | numeric | | | NOT NULL |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now(), NOT NULL |

## star_aggregations

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ユーザーID | user_id | uuid | ○ | auth.users.id | |
| 対象年月 | target_year_month | bpchar | ○ | | |
| 合計ポイント | total_points | numeric | | | デフォルト: 0, NOT NULL |
| 有効期限 | expiration_datetime | timestamptz | | | NOT NULL |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 期限切れフラグ | expiration_flag | smallint | | | デフォルト: 0, NOT NULL |

## star_rewards_exchange_items

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ | | AUTO INCREMENT |
| 短縮名 | short_name | text | | | NOT NULL |
| 商品名 | name | text | | | NOT NULL |
| 画像URL | image_url | text | | | |
| 必要ポイント | points | integer | | | NOT NULL |

## star_usage

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ | | デフォルト: gen_random_uuid() |
| ユーザーID | user_id | uuid | | auth.users.id | NOT NULL |
| 注文ID | order_id | text | | | |
| 交換商品ID | exchange_item_id | integer | | star_rewards_exchange_items.id | |
| 使用ポイント | point_used | numeric | | | NOT NULL |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now(), NOT NULL |

## staff

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| スタッフ番号 | staff_number | varchar(50) | ○ | | NOT NULL |
| スタッフ名 | staff_name | varchar(100) | | | NOT NULL |
| メールアドレス | email | varchar(255) | | | |
| 電話番号 | phone | varchar(20) | | | |
| 雇用形態 | employment_type | varchar(20) | | | |
| 入社日 | hire_date | date | | | |
| 退職日 | termination_date | date | | | |
| 有効フラグ | is_active | boolean | | | デフォルト: true |
| 作成日時 | created_at | timestamptz | | | デフォルト: now() |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now() |

## staff_schedules

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | bigint | ○ | | AUTO INCREMENT |
| 日付 | date | date | | | NOT NULL |
| スタッフ番号 | staff_number | varchar(50) | | staff.staff_number | NOT NULL |
| 店舗番号 | store_number | varchar(50) | | | |
| 第1時間帯勤務 | period_1 | boolean | | | デフォルト: false |
| 第2時間帯勤務 | period_2 | boolean | | | デフォルト: false |
| 第3時間帯勤務 | period_3 | boolean | | | デフォルト: false |
| 第4時間帯勤務 | period_4 | boolean | | | デフォルト: false |
| 第5時間帯勤務 | period_5 | boolean | | | デフォルト: false |
| 作成日時 | created_at | timestamptz | | | デフォルト: now() |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now() |

## store_profiles

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ | | AUTO INCREMENT |
| 店舗番号 | store_number | bpchar | | stores.store_number | NOT NULL |
| ユーザーID | user_id | uuid | | auth.users.id | NOT NULL, UNIQUE制約 |
| 作成日時 | created_at | timestamptz | | | デフォルト: now() |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now() |

## stores

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ | | AUTO INCREMENT |
| 店舗番号 | store_number | bpchar | | | NOT NULL, UNIQUE制約 |
| 店舗名 | store_name | text | | | NOT NULL |
| 都道府県ID | prefecture_id | integer | | prefectures.id | NOT NULL |
| 住所 | address | text | | | NOT NULL |
| オープン日 | opening_date | date | | | NOT NULL |
| 閉店日 | closing_date | date | | | |
| 作成日時 | created_at | timestamptz | | | デフォルト: CURRENT_TIMESTAMP |
| 更新日時 | updated_at | timestamptz | | | デフォルト: CURRENT_TIMESTAMP |
| 閉店時間 | closing_time | time | | | デフォルト: '21:00:00', NOT NULL |
| 開店時間 | opening_time | time | | | デフォルト: '09:00:00', NOT NULL |
| 緯度 | latitude | float8 | | | デフォルト: 0.0, NOT NULL |
| 経度 | longitude | float8 | | | デフォルト: 0.0, NOT NULL |
| ドライブスルー利用可能 | is_drive_thru_available | bpchar | | | デフォルト: '0', CHECK制約: is_drive_thru_available IN ('0', '1') |

## temperature_types

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| 温度タイプID | temperature_type_id | integer | ○ | | AUTO INCREMENT |
| タイプ名 | type_name | text | | | NOT NULL |

## user_fcm_tokens

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| FCMトークン | fcm_token | text | | | |
| 通知設定 | is_notify | integer | | | デフォルト: 0, NOT NULL |
| ユーザーID | user_id | uuid | ○ | auth.users.id | |

## user_mail_settings

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ | | デフォルト: uuid_generate_v4() |
| ユーザーID | user_id | uuid | | auth.users.id | NOT NULL, UNIQUE制約 |
| リワード関連メール送信設定 | is_send_related_rewards | integer | | | デフォルト: 0, NOT NULL |
| 商品先行告知メール送信設定 | is_send_advance_product_announce | integer | | | デフォルト: 0, NOT NULL |
| HTMLメール設定 | is_html_mail | integer | | | デフォルト: 1, NOT NULL |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now(), NOT NULL |

## user_profile_details

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | uuid | ○ | | デフォルト: uuid_generate_v4() |
| ユーザーID | user_id | uuid | | auth.users.id | NOT NULL, UNIQUE制約 |
| 生年月日 | birthday | text | | | |
| 性別 | sex | integer | | | |
| 電話番号 | tele_num | text | | | |
| 郵便番号 | postal_code | text | | | |
| 都道府県ID | prefecture_id | integer | | prefectures.id | |
| 住所1 | address1 | text | | | |
| 住所2 | address2 | text | | | |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now(), NOT NULL |

## user_tickets

| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |
|--------|----------|-----|--------|----------|------|
| ID | id | integer | ○ | | AUTO INCREMENT |
| ユーザーID | user_id | uuid | | auth.users.id | NOT NULL |
| チケットタイプ | ticket_type | text | | | NOT NULL, 値: 'STAR_REWARD'（スター交換）、'PROMOTION'（プロモーション）、'SPECIAL_OFFER'（特別オファー） |
| 定義ID | definition_id | integer | | | NOT NULL, ticket_typeに応じて参照先が異なる: STAR_REWARD→star_rewards_exchange_items.id、PROMOTION→e_tickets_promotions.id、SPECIAL_OFFER→e_tickets_special_offers.id |
| 有効期限 | expired_at | timestamptz | | | NOT NULL, このチケットの利用期限 |
| 利用済フラグ | is_used | boolean | | | デフォルト: false, NOT NULL |
| 作成日時 | created_at | timestamptz | | | デフォルト: now(), NOT NULL |
| 更新日時 | updated_at | timestamptz | | | デフォルト: now(), NOT NULL |

---

## マテリアライズドビュー (Materialized Views)

### mv_products_catalog

商品カタログの結合済みビュー。`products` / `categories` / `product_sizes` / `sizes` / `product_temperature_types` / `temperature_types` を JOIN した読み取り専用スナップショット。

> **更新手順**: `supabase_schema/supabase/mv_products_catalog_guide.md` を参照

| 論理名 | カラム名 | 型 | 元テーブル | 備考 |
|--------|----------|----|------------|------|
| 商品ID | product_id | integer | products | |
| 商品名 | product_name | varchar | products | |
| カテゴリID | category_id | integer | products | |
| カテゴリ名 | category_name | varchar | categories | |
| 説明 | description | text | products | |
| 商品画像パス | product_image_path | varchar | products | Supabase Storage のパス |
| 販売タイプ | sale_type | text | products | |
| 表示順 | display_order | integer | products | 昇順でソート |
| サイズID | size_id | integer | sizes | LEFT JOIN（NULLあり） |
| サイズ名 | size_name | varchar | sizes | LEFT JOIN（NULLあり） |
| 価格 | price | integer | product_sizes | LEFT JOIN（NULLあり） |
| 温度タイプID | temperature_type_id | integer | product_temperature_types | LEFT JOIN（NULLあり） |
| 温度タイプ名 | temperature_type_name | varchar | temperature_types | LEFT JOIN（NULLあり） |

**インデックス**: `idx_mv_products_catalog_unique (product_id, COALESCE(size_id,-1), COALESCE(temperature_type_id,-1))` UNIQUE

---

## テーブル概要

このデータベースは、コーヒーショップやカフェなどの店舗アプリケーション向けのテーブル構成となっています。主な機能領域は以下の通りです：

### ユーザー管理
- `user_profile_details`: ユーザープロフィール詳細
- `user_mail_settings`: メール設定
- `user_fcm_tokens`: プッシュ通知トークン
- `pre_signup_users`: 事前登録ユーザー

### 商品・カテゴリ管理
- `products`: 商品マスタ
- `categories`: 商品カテゴリ
- `sizes`: サイズマスタ
- `temperature_types`: 温度タイプ（ホット/アイス等）
- `product_sizes`: 商品とサイズの関連
- `product_temperature_types`: 商品と温度タイプの関連
- `mv_products_catalog` *(Materialized View)*: 上記6テーブルを結合した商品カタログスナップショット

### 注文・カート機能
- `orders`: 注文情報
- `orders_detail`: 注文明細
- `carts`: カート情報
- `carts_detail`: カート明細

### 店舗管理
- `stores`: 店舗マスタ
- `store_profiles`: 店舗プロフィール
- `prefectures`: 都道府県マスタ

### スタッフ・シフト管理
- `staff`: スタッフマスタ
- `staff_schedules`: スタッフシフトスケジュール

### ポイント・リワード機能
- `star_acquisitions`: ポイント獲得履歴
- `star_aggregations`: ポイント集計
- `star_usage`: ポイント使用履歴
- `star_rewards_exchange_items`: 交換商品マスタ

### eチケット機能
- `e_tickets_promotions`: プロモーション系eチケット定義（割引率/割引額）
- `e_tickets_special_offers`: 特別オファー系eチケット定義（特別価格商品）
- `user_tickets`: ユーザー保有eチケット実体

### 決済・カード機能
- `cards`: ユーザーカード情報
- `purchase_history`: 購入履歴

### その他
- `sample`: サンプルテーブル
- `spatial_ref_sys`: 空間参照システム（地理情報用）

## 主な更新点

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

合計28テーブルで構成されており、カフェ・コーヒーショップアプリの主要機能をカバーする包括的なデータベース設計となっています。