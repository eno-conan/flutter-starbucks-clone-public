# データアーカイブ運用ガイド（Issue#544）

## 概要

18ヶ月以上経過した注文・スター履歴データを専用アーカイブテーブルへ移動し、
運用テーブルのパフォーマンスを維持するための仕組み。
pg_cron による定期自動実行と、SQL Editor からの手動即時実行の両方に対応している。

---

## アーカイブ対象と保持期間

| テーブル | アーカイブ先 | 保持期間 | 備考 |
|----------|-------------|----------|------|
| `orders` | `orders_archive` | 18ヶ月 | FK依存を考慮して最後に処理 |
| `orders_detail` | `orders_detail_archive` | 18ヶ月（ordersに連動） | ordersより先に処理 |
| `star_acquisitions` | `star_acquisitions_archive` | 18ヶ月（ordersに連動） | ordersより先に処理 |
| `star_usage` | `star_usage_archive` | 18ヶ月 | ordersと独立して処理可能 |
| `user_tickets` | なし（削除のみ） | 有効期限切れから3ヶ月 | マーケティング価値なし |
| `carts` / `carts_detail` | なし（削除のみ） | 最終更新から30日 | 未決済カートのみ対象 |

---

## マイグレーションファイル構成

```
supabase/migrations/
├── 20260319000001_create_archive_tables.sql          # アーカイブテーブル作成
└── 20260319000002_create_archive_and_cleanup_functions.sql  # アーカイブ関数作成
cron/
└── archive_data.sql                                  # pg_cronスケジュール設定
```

---

## アーカイブテーブルの特徴

- **FK なし**: アーカイブ後に参照元テーブルが削除されるため外部キー制約を持たない
- **RLS 有効・`service_role` のみアクセス可**: 一般ユーザーからは参照不可
- **`archived_at` カラム**: アーカイブ実行日時を自動記録
- **`ON CONFLICT DO NOTHING`**: 二重実行時の重複を安全にスキップ

---

## アーカイブ関数

### 1. `archive_old_orders(p_retention_months)`

注文データのアーカイブ。FK 依存関係を考慮した処理順序：

```
star_acquisitions → orders_detail → orders
（アーカイブ→削除の順で各テーブルを処理）
```

戻り値（jsonb）:
```json
{
  "cutoff_date": "2024-09-19T00:00:00+00:00",
  "archived_orders": 42,
  "archived_details": 156,
  "archived_acquisitions": 38
}
```

### 2. `archive_old_star_usage(p_retention_months)`

スター使用履歴のアーカイブ（orders とは独立して処理可能）。

戻り値（jsonb）:
```json
{
  "cutoff_date": "2024-09-19T00:00:00+00:00",
  "archived_count": 29
}
```

### 3. `cleanup_expired_user_tickets(p_grace_months)`

有効期限切れから猶予期間を超えたチケットを削除（アーカイブなし）。

戻り値（jsonb）:
```json
{
  "cutoff_date": "2026-12-19T00:00:00+00:00",
  "deleted_count": 10
}
```

### 4. `cleanup_abandoned_carts(p_retention_days)`

放棄カートを削除。FK 依存順（`carts_detail` → `carts`）で処理。

戻り値（jsonb）:
```json
{
  "cutoff_date": "2026-02-17T00:00:00+00:00",
  "deleted_carts": 5,
  "deleted_details": 13
}
```

---

## 手動即時実行（SQL Editor）

### 通常実行（本番向け）

```sql
SELECT public.archive_old_orders(18);
SELECT public.archive_old_star_usage(18);
SELECT public.cleanup_expired_user_tickets(3);
SELECT public.cleanup_abandoned_carts(30);
```

### 動作確認用（全データを対象にする）

```sql
-- 保持期間0 = NOW()より古い全データが対象（実質すべて）
SELECT public.archive_old_orders(0);
SELECT public.archive_old_star_usage(0);
SELECT public.cleanup_expired_user_tickets(0);
SELECT public.cleanup_abandoned_carts(0);
```

### 実行前後の件数確認

```sql
-- 実行前
SELECT
  (SELECT count(*) FROM public.orders)            AS orders,
  (SELECT count(*) FROM public.orders_detail)     AS orders_detail,
  (SELECT count(*) FROM public.star_acquisitions) AS star_acquisitions,
  (SELECT count(*) FROM public.star_usage)        AS star_usage;

-- 実行後（アーカイブ先の確認）
SELECT
  (SELECT count(*) FROM public.orders_archive)            AS orders_archive,
  (SELECT count(*) FROM public.orders_detail_archive)     AS detail_archive,
  (SELECT count(*) FROM public.star_acquisitions_archive) AS acq_archive,
  (SELECT count(*) FROM public.star_usage_archive)        AS usage_archive;
```

---

## pg_cron による定期自動実行

`cron/archive_data.sql` を SQL Editor で実行してジョブを登録する。

| ジョブ名 | スケジュール（UTC） | JST換算 | 内容 |
|----------|--------------------|---------|----|
| `archive-old-orders` | 毎月1日 18:00 | 翌2日 3:00 | 注文データ（18ヶ月） |
| `archive-old-star-usage` | 毎月1日 18:05 | 翌2日 3:05 | スター使用履歴（18ヶ月） |
| `cleanup-expired-tickets` | 毎月1日 18:10 | 翌2日 3:10 | 期限切れチケット（3ヶ月） |
| `cleanup-abandoned-carts` | 毎週日曜 18:00 | 月曜 3:00 | 放棄カート（30日） |

※ orders アーカイブ完了後に star_usage を5分ずらして実行しているのは、DB負荷の分散のため。

### ジョブ登録・確認

```sql
-- ジョブ登録（archive_data.sql の内容を実行）
-- Supabase Dashboard > Extensions で pg_cron が有効なこと

-- 登録確認
SELECT jobid, jobname, schedule, command, active
FROM cron.job
ORDER BY jobname;
```

### ジョブ実行履歴の確認

```sql
SELECT jobid, runid, status, start_time, end_time, return_message
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 20;
```

---

## TODO

- [ ] **Supabase Storage バケット `archives` の作成**
  - アーカイブテーブルのデータを長期保存用に JSONL/CSV エクスポートして Storage に退避する想定
  - バケット作成後は Edge Function またはスクリプトで定期エクスポートを実装する
  - 参考実装: `partitioning_archiving_guide.md` の「2-C. Supabase Storage へのアップロード」

---

## 関連ファイル

| ファイル | 内容 |
|--------|------|
| `migrations/20260319000001_create_archive_tables.sql` | アーカイブテーブル DDL |
| `migrations/20260319000002_create_archive_and_cleanup_functions.sql` | アーカイブ関数定義 |
| `cron/archive_data.sql` | pg_cron スケジュール設定 |
| `partitioning_archiving_guide.md` | パーティショニング戦略・Storage連携の参考実装 |
