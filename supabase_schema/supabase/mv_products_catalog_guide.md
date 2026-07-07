# mv_products_catalog 更新ガイド

## 概要

`mv_products_catalog` は商品関連テーブルを結合したマテリアライズドビュー（MV）です。
MVは実テーブルのスナップショットであるため、元テーブルを変更しただけでは自動で反映されません。

**2026-02-26 以降**: ベーステーブル変更時に自動リフレッシュトリガーが発火するため、通常は手動でのリフレッシュは不要です。
手動リフレッシュが必要なケース（例: マイグレーション後の初回反映）は「手動更新手順」を参照してください。

---

## MVの構成

```
products                 ← 商品マスタ（product_image_path, sale_type, display_order を含む）
  ├── categories         ← カテゴリ名
  ├── product_sizes      ← サイズ別価格
  │     └── sizes        ← サイズ名
  └── product_temperature_types ← 温度タイプ
        └── temperature_types   ← 温度タイプ名
```

---

## 自動リフレッシュ（トリガー）

`20260226100003_add_triggers_auto_refresh_mv_products_catalog.sql` で設定済み。

### 仕組み

ベーステーブル（下記6テーブル）に対して `INSERT / UPDATE / DELETE` が実行されると、
`AFTER ... FOR EACH STATEMENT` トリガーが発火し、`refresh_mv_products_catalog_trigger()` が呼ばれます。
この関数は `REFRESH MATERIALIZED VIEW public.mv_products_catalog`（非 CONCURRENT）を実行します。

### トリガー一覧

| トリガー名 | 対象テーブル |
|-----------|------------|
| `trg_refresh_mv_on_products_change` | `products` |
| `trg_refresh_mv_on_categories_change` | `categories` |
| `trg_refresh_mv_on_product_sizes_change` | `product_sizes` |
| `trg_refresh_mv_on_sizes_change` | `sizes` |
| `trg_refresh_mv_on_product_temperature_types_change` | `product_temperature_types` |
| `trg_refresh_mv_on_temperature_types_change` | `temperature_types` |

### 技術的制約

| 方法 | トランザクション内実行 | 採用 |
|------|----------------------|------|
| `REFRESH MATERIALIZED VIEW CONCURRENTLY` | ❌ 不可 | ✗ |
| `REFRESH MATERIALIZED VIEW`（非 CONCURRENT） | ✅ 可能 | ✅ |

トリガーはトランザクション内で動作するため、非 CONCURRENT を採用しています。
ロールバック時はMVのリフレッシュも同時にロールバックされるため、整合性は保たれます。

---

## 手動更新手順

### ステップ1: 元テーブル（products）を更新

```sql
-- 例: 商品画像パスを更新
UPDATE public.products
SET product_image_path = 'products/product_5.png'
WHERE product_id = 5;

-- 例: 複数商品を一括更新
UPDATE public.products SET product_image_path = 'products/product_1.png'  WHERE product_id = 1;
UPDATE public.products SET product_image_path = 'products/product_2.png'  WHERE product_id = 2;
-- ...
```

### ステップ2: MVをリフレッシュ

```sql
REFRESH MATERIALIZED VIEW public.mv_products_catalog;
```

> **注意**: `CONCURRENTLY` オプションは使用しないこと。
> このプロジェクトのユニークインデックスは `COALESCE` 式を使用しているため、
> PostgreSQLのバージョンによっては `CONCURRENTLY` が機能しない場合がある。

### ステップ3: 反映確認

```sql
SELECT product_id, product_name, product_image_path
FROM public.mv_products_catalog
GROUP BY product_id, product_name, product_image_path
ORDER BY product_id;
```

---

## 更新が必要なタイミング

| 操作 | MVの更新 | 備考 |
|------|---------|------|
| `products` テーブルの更新 | ✅ 自動（トリガー） | |
| `categories` テーブルの更新 | ✅ 自動（トリガー） | |
| `product_sizes` テーブルの更新 | ✅ 自動（トリガー） | |
| `sizes` テーブルの更新 | ✅ 自動（トリガー） | |
| `product_temperature_types` の更新 | ✅ 自動（トリガー） | |
| `temperature_types` の更新 | ✅ 自動（トリガー） | |
| Supabaseストレージのファイルのみ差し替え | ❌ 不要 | URLは同じため |
| マイグレーション適用直後 | ⚠️ 手動で実行 | トリガーが未設定の期間は手動リフレッシュが必要 |

---

## SupabaseストレージとMVの関係

`product_image_path` は Supabase Storage 上のファイルパスです（例: `products/product_5.png`）。
Flutter アプリ側では `getPublicUrl(imagePath)` でURLに変換して表示します。

### 画像を更新する場合の注意点

| パターン | 対応 |
|----------|------|
| **新しいパスで追加**（例: `product_5_v2.png`） | productsテーブルを更新 → MVをリフレッシュ → 即反映 |
| **同じパスでファイル差し替え** | MVリフレッシュ不要だが、Supabase CDNキャッシュにより最大1時間古い画像が表示される可能性あり |

---

## Flutter側のキャッシュについて

アプリ側にも以下のキャッシュがあります（開発中は無効化済み）:

| キャッシュ | 場所 | 無効化方法 |
|-----------|------|-----------|
| セッションキャッシュ | `ProductRepository._sessionCache` | コメントアウト済み（`product.dart`） |
| SQLiteキャッシュ | `supabase_cache.db` の `cache` テーブル | コメントアウト済み（`product.dart`） |
| Flutter画像キャッシュ | `Image.network()` のメモリキャッシュ | アプリ完全再起動で解消 |

本番環境に戻す際は `lib/data/repository/product.dart` のコメントアウトを解除してください。

---

## 関連ファイル

| ファイル | 説明 |
|---------|------|
| `supabase_schema/supabase/migrations/20260226100000_create_materialized_view_mv_products_catalog.sql` | MV作成・ユニークインデックス・`refresh_products_catalog()` 関数定義 |
| `supabase_schema/supabase/migrations/20260226100001_update_rpc_get_products_with_sizes_and_categories.sql` | MVを使用するRPC |
| `supabase_schema/supabase/migrations/20260226100002_fix_mv_products_catalog_access.sql` | RPCをSECURITY DEFINERに変更・直接アクセス禁止 |
| `supabase_schema/supabase/migrations/20260226100003_add_triggers_auto_refresh_mv_products_catalog.sql` | 自動リフレッシュトリガー |
| `lib/data/repository/product.dart` | Flutter側の商品データ取得 |
