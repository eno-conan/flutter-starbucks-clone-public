# パーティショニング & アーカイブ リファレンスガイド

## Context

テーブルスキーマを分析した結果。実施する際に知っておくべき
コマンド・制約・移行手順をまとめたリファレンス。

---

## 1. パーティショニング（優先度：中）

### 前提：PostgreSQL 宣言的パーティショニングの注意点

既存テーブルを後からパーティション化する `ALTER TABLE ... PARTITION BY` コマンドは
**PostgreSQL に存在しない**。必ず次の手順が必要:

```
1. 新しいパーティションテーブルを作成
2. 既存データをコピー (INSERT INTO ... SELECT *)
3. テーブルを差し替え (RENAME)
4. 動作確認後に旧テーブルを削除
```

パーティションキーは **PRIMARY KEY と UNIQUE 制約に含める必要がある**。

---

### 1-A. orders テーブル（月次 RANGE パーティション）

#### スキーマ上の課題

| 制約 | 現状 | パーティション化後の変更 |
|------|------|--------------------------|
| PK | `id` (uuid) | `(id, created_at)` に変更必須 |
| UNIQUE | `order_id` のみ | `(order_id, created_at)` に変更必須 ← **注意** |
| FK参照元 | `orders_detail.order_id` → `orders.order_id` | 対応要（後述） |
| FK参照元 | `star_acquisitions.order_id` → `orders.order_id` | 対応要 |

> **重要**: `order_id` 単独での UNIQUE 制約はパーティション化後に保証できない。
> パーティションをまたぐ UNIQUE はサポートされないため、
> 「同じ `order_id` が別月のパーティションに入らない」ことを
> アプリ側で担保する必要がある（通常は問題ない）。

#### 移行コマンド

```sql
-- ① 新しいパーティションテーブルを作成
CREATE TABLE orders_partitioned (
    id                  uuid          NOT NULL DEFAULT gen_random_uuid(),
    order_id            varchar       NOT NULL,
    user_id             uuid          NOT NULL REFERENCES auth.users(id),
    order_type          smallint      NOT NULL CHECK (order_type IN (1, 2)),
    pickup_number       text          NOT NULL,
    price_without_tax   integer       NOT NULL,
    price_with_tax      integer       NOT NULL,
    payment_method      text          NOT NULL,
    created_at          timestamptz   NOT NULL DEFAULT now(),
    updated_at          timestamptz   NOT NULL DEFAULT now(),
    provided_status     text          DEFAULT '0'
        CHECK (provided_status IN ('0', '1', '2', '99')),
    store_number        bpchar        NOT NULL REFERENCES stores(store_number),
    usage               smallint      DEFAULT 1 CHECK (usage IN (1, 2, 3)),
    PRIMARY KEY (id, created_at)          -- ← created_at を必ず含める
) PARTITION BY RANGE (created_at);

-- ② 月次パーティションを作成（必要な月分）
CREATE TABLE orders_y2025m01 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE orders_y2025m02 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
-- ... 月ごとに繰り返す
CREATE TABLE orders_y2026m01 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE orders_y2026m02 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

-- ③ デフォルトパーティション（予期しない月のデータ受け取り用）
CREATE TABLE orders_default PARTITION OF orders_partitioned DEFAULT;

-- ④ 既存データをコピー
INSERT INTO orders_partitioned SELECT * FROM orders;

-- ⑤ インデックスを各パーティションに作成
-- （親テーブルに作成すると自動で各パーティションに伝播する）
CREATE INDEX ON orders_partitioned (user_id, created_at);
CREATE INDEX ON orders_partitioned (store_number, created_at);

-- ⑥ order_id のユニークインデックス（created_at を含めて代替）
CREATE UNIQUE INDEX ON orders_partitioned (order_id, created_at);

-- ⑦ テーブル差し替え（メンテナンスウィンドウ内で実施）
BEGIN;
  ALTER TABLE orders RENAME TO orders_old;
  ALTER TABLE orders_partitioned RENAME TO orders;
COMMIT;

-- ⑧ 動作確認後に旧テーブルを削除
-- DROP TABLE orders_old;
```

#### pg_partman で月次パーティションを自動作成

```sql
-- Supabase Dashboard の Extensions から pg_partman を有効化
CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman;

-- 月次自動管理を設定
SELECT partman.create_parent(
    p_parent_table => 'public.orders',
    p_control      => 'created_at',
    p_type         => 'range',
    p_interval     => '1 month',
    p_premake      => 3   -- 3ヶ月先まで事前作成
);

-- pg_cron で定期メンテナンス（パーティション自動追加・削除）
SELECT cron.schedule('0 0 1 * *', $$SELECT partman.run_maintenance()$$);
```

---

### 1-B. orders_detail テーブル（パーティションワイズ結合のための設計）

#### 課題：タイムスタンプがない

`orders_detail` には日付カラムがない。パーティションワイズ結合には
**両テーブルが同じパーティションキー・同じ境界** を持つ必要がある。

**選択肢**

| 選択肢 | 内容 | 推奨度 |
|--------|------|--------|
| A | `order_created_at` カラムを追加（orders.created_at を引き継ぐ） | ★ 推奨 |
| B | orders のみパーティション化、orders_detail はインデックスで対応 | 簡単だが効果限定 |

#### 選択肢A の実装コマンド

```sql
-- ① orders_detail に order_created_at を追加したパーティションテーブルを作成
CREATE TABLE orders_detail_partitioned (
    id                    uuid          DEFAULT uuid_generate_v4(),
    order_id              varchar,
    user_id               uuid          REFERENCES auth.users(id),
    product_id            integer       REFERENCES products(product_id),
    temperature_type_id   integer       REFERENCES temperature_types(temperature_type_id),
    size_id               integer       REFERENCES sizes(size_id),
    count                 integer       NOT NULL,
    subtotal_without_tax  integer       NOT NULL,
    order_created_at      timestamptz   NOT NULL,  -- ← orders.created_at を引き継ぐ
    PRIMARY KEY (id, order_created_at)
) PARTITION BY RANGE (order_created_at);

-- ② 同じ境界でパーティション作成（orders と同じ月）
CREATE TABLE orders_detail_y2025m01 PARTITION OF orders_detail_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
-- ... 月ごとに繰り返す

-- ③ データコピー（orders と JOIN して created_at を引き継ぐ）
INSERT INTO orders_detail_partitioned
SELECT
    od.id,
    od.order_id,
    od.user_id,
    od.product_id,
    od.temperature_type_id,
    od.size_id,
    od.count,
    od.subtotal_without_tax,
    o.created_at AS order_created_at
FROM orders_detail od
JOIN orders o ON od.order_id = o.order_id;

-- ④ テーブル差し替え
ALTER TABLE orders_detail RENAME TO orders_detail_old;
ALTER TABLE orders_detail_partitioned RENAME TO orders_detail;

-- ⑤ FK参照の再作成（orders.order_id → 新 orders テーブル）
ALTER TABLE orders_detail
    ADD CONSTRAINT fk_orders_detail_order_id
    FOREIGN KEY (order_id, order_created_at)
    REFERENCES orders (order_id, created_at);
```

#### パーティションワイズ結合の確認

```sql
-- パーティションワイズ結合の有効化
SET enable_partitionwise_join = on;

-- 実行計画で確認
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.*, od.*
FROM orders o
JOIN orders_detail od
  ON od.order_id = o.order_id
 AND od.order_created_at = o.created_at   -- パーティションキーで結合
WHERE o.created_at BETWEEN '2026-01-01' AND '2026-02-01';

-- "Partitioned Hash Join" が表示されれば成功
-- "Hash Join on orders_y2026m01 + orders_detail_y2026m01" のような形になる
```

---

### 1-C. staff_schedules テーブル（月次 RANGE パーティション）

`date` カラム（date型）が既にあるため、3テーブルの中で最もシンプルに実装できる。

#### スキーマ上の課題

| 制約 | 現状 | パーティション化後 |
|------|------|-------------------|
| PK | `id` (bigint AUTO INCREMENT) | `(id, date)` に変更必須 |
| FK参照元 | なし | 対応不要 |

#### 移行コマンド

```sql
-- ① 新しいパーティションテーブルを作成
CREATE TABLE staff_schedules_partitioned (
    id           bigint        NOT NULL GENERATED ALWAYS AS IDENTITY,
    date         date          NOT NULL,
    staff_number varchar(50)   NOT NULL REFERENCES staff(staff_number),
    store_number varchar(50),
    period_1     boolean       DEFAULT false,
    period_2     boolean       DEFAULT false,
    period_3     boolean       DEFAULT false,
    period_4     boolean       DEFAULT false,
    period_5     boolean       DEFAULT false,
    created_at   timestamptz   DEFAULT now(),
    updated_at   timestamptz   DEFAULT now(),
    PRIMARY KEY (id, date)    -- ← date を必ず含める
) PARTITION BY RANGE (date);

-- ② 月次パーティションを作成
CREATE TABLE staff_schedules_y2026m01 PARTITION OF staff_schedules_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE staff_schedules_y2026m02 PARTITION OF staff_schedules_partitioned
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
-- ...

-- ③ デフォルトパーティション
CREATE TABLE staff_schedules_default PARTITION OF staff_schedules_partitioned DEFAULT;

-- ④ 既存データをコピー
INSERT INTO staff_schedules_partitioned (date, staff_number, store_number,
    period_1, period_2, period_3, period_4, period_5, created_at, updated_at)
SELECT date, staff_number, store_number,
    period_1, period_2, period_3, period_4, period_5, created_at, updated_at
FROM staff_schedules;
-- ※ GENERATED ALWAYS AS IDENTITY の id は自動採番されるため id を除外

-- ⑤ インデックス
CREATE INDEX ON staff_schedules_partitioned (date, store_number);
CREATE INDEX ON staff_schedules_partitioned (staff_number, date);

-- ⑥ テーブル差し替え
ALTER TABLE staff_schedules RENAME TO staff_schedules_old;
ALTER TABLE staff_schedules_partitioned RENAME TO staff_schedules;

-- ⑦ 動作確認後に削除
-- DROP TABLE staff_schedules_old;
```

#### パーティションプルーニングの確認

```sql
-- 特定の月のデータだけを読む場合のクエリ
EXPLAIN SELECT * FROM staff_schedules
WHERE date BETWEEN '2026-02-01' AND '2026-02-28';

-- "Seq Scan on staff_schedules_y2026m02" のみ表示されれば成功
-- （他パーティションがスキャンされていないことを確認）
```

---

## 2. アーカイブ（優先度：低）

### 2-A. パーティション化済みテーブルのアーカイブ（推奨）

パーティション化済みであれば、古いパーティションをそのまま切り離して
アーカイブ→削除できる。**これが最もクリーンな手順**。

```sql
-- ① 古いパーティションを切り離す（データは残る、親テーブルから見えなくなる）
ALTER TABLE orders DETACH PARTITION orders_y2024m01;

-- ② 切り離したパーティションのデータをCSVにエクスポート
-- psql クライアントから実行する場合:
\COPY orders_y2024m01 TO '/tmp/orders_archive_2024m01.csv' WITH (FORMAT CSV, HEADER);

-- または Supabase SQL Editor では STDOUT 経由
COPY orders_y2024m01 TO STDOUT WITH (FORMAT CSV, HEADER);

-- ③ エクスポート確認後にパーティションを削除
DROP TABLE orders_y2024m01;
```

### 2-B. パーティション化していない場合のアーカイブ

```sql
-- ① アーカイブ対象データを別テーブルに移動
CREATE TABLE orders_archive_2024 AS
SELECT * FROM orders
WHERE created_at < '2025-01-01';

-- ② CSVにエクスポート
\COPY orders_archive_2024 TO '/tmp/orders_archive_2024.csv' WITH (FORMAT CSV, HEADER);

-- ③ Supabase Storage へのアップロード（Edge Function から）
-- （後述の Edge Function コードを参照）

-- ④ 元テーブルから削除（参照整合性を先に確認）
-- FK参照をチェック: orders_detail, star_acquisitions が先に削除されていること
DELETE FROM orders WHERE created_at < '2025-01-01';

-- ⑤ 一時テーブルを削除
DROP TABLE orders_archive_2024;
```

### 2-C. Supabase Storage へのエクスポート（Issue#544 実装済み）

#### 全体フロー

```
pg_cron（毎月1日 19:00 UTC）
  └─ trigger_export_archive_to_storage() [PostgreSQL 関数]
       └─ net.http_post() [pg_net]
            └─ exportArchiveToStorage [Edge Function]
                 ├─ orders_archive から当日 archived_at のデータを取得
                 ├─ orders_detail_archive  〃
                 ├─ star_acquisitions_archive  〃
                 ├─ star_usage_archive  〃
                 └─ Storage "archives" バケットへ JSONL アップロード
```

> アーカイブテーブルのデータはアップロード後も**削除しない**（DB + Storage の二重保持）。
> アーカイブテーブルへの移動は `archive_old_orders()` / `archive_old_star_usage()` が担当（18:00 UTC 実行）。
> エクスポートは 1 時間後の 19:00 UTC に実行してバッファを確保。

#### Storage のファイル構成

```
archives/
├── orders/
│   └── 2026_03_01.jsonl
├── orders_detail/
│   └── 2026_03_01.jsonl
├── star_acquisitions/
│   └── 2026_03_01.jsonl
└── star_usage/
    └── 2026_03_01.jsonl
```

ファイル名は `YYYY_MM_DD.jsonl`（アーカイブ実行日）。同日再実行で上書き（upsert）。

#### 関連ファイル

| ファイル | 役割 |
|--------|------|
| `supabase/migrations/20260319000003_create_trigger_export_to_storage_function.sql` | pg_net 有効化 + `trigger_export_archive_to_storage()` 関数 |
| `cron/export_to_storage.sql` | pg_cron スケジュール定義 |
| `supabase/functions/exportArchiveToStorage/index.ts` | Edge Function 本体 |

#### デプロイ手順

```bash
# verify_jwt は config.toml の [functions.exportArchiveToStorage] で管理する（false）。
# trigger_export_archive_to_storage() が Authorization ヘッダーを付けないため false が必須。
# CLI フラグは config.toml を上書きするため付けない。
supabase functions deploy exportArchiveToStorage
```

#### 初回セットアップ（SQL Editor で一度だけ実行）

```sql
-- Vault に Supabase URL を登録
SELECT vault.create_secret(
    'https://<project-ref>.supabase.co',
    'supabase_url'
);

-- pg_cron スケジュールを登録（cron/export_to_storage.sql の内容を実行）
SELECT cron.schedule(
    'export-archive-to-storage',
    '0 19 1 * *',
    $$SELECT public.trigger_export_archive_to_storage()$$
);
```

#### 手動実行・動作確認

```sql
-- 手動で即時実行
SELECT public.trigger_export_archive_to_storage();

-- pg_net のレスポンス確認（非同期のため数秒後に実行）
SELECT id, status_code, content
FROM net._http_response
ORDER BY id DESC
LIMIT 5;
-- status_code: 200 → 成功
```

### 2-D. アーカイブデータの復元手順

```sql
-- Storage からダウンロードしたファイルを復元
\COPY orders FROM '/tmp/orders_archive_2024m01.csv' WITH (FORMAT CSV, HEADER);

-- または JSONL の場合は json_populate_record で変換
INSERT INTO orders
SELECT * FROM json_populate_recordset(
    null::orders,
    pg_read_file('/tmp/orders_archive_2024m01.jsonl')::json
);
```

---

## 3. 実施時の全体的な注意点

### Supabase 固有の考慮事項

| 項目 | 注意内容 |
|------|----------|
| RLS ポリシー | 新テーブルに既存の RLS ポリシーを再適用する必要あり |
| トリガー | `updated_at` 自動更新トリガーがあれば再作成 |
| RPC 関数 | `get_store_wait_times` 等がテーブル名を参照している場合は更新 |
| FK 制約 | PostgreSQL 12以降（Supabase は対応済み）でパーティション化テーブルへのFKが利用可能 |
| 接続プール | PgBouncer 使用時はトランザクションモードで `COPY` コマンドに制限あり |

### データ移行のリスク管理

```bash
# 事前: Supabase の Point-in-Time Recovery が有効であることを確認
# Dashboard > Settings > Database > Point in Time Recovery

# ローカルでテスト
supabase start
supabase db push  # マイグレーション適用してテスト

# 本番移行は必ずメンテナンスウィンドウ内で実施
# テーブル差し替えの RENAME は瞬時だが、
# INSERT INTO ... SELECT * は大量データがある場合に時間がかかる
```

### マイグレーションファイルの分割構成（推奨）

```
supabase/migrations/
├── YYYYMMDD000001_create_orders_partitioned.sql      # テーブル・パーティション作成
├── YYYYMMDD000002_migrate_orders_data.sql            # データコピー
├── YYYYMMDD000003_swap_orders_table.sql              # テーブル差し替え
├── YYYYMMDD000004_create_orders_detail_partitioned.sql
├── YYYYMMDD000005_migrate_orders_detail_data.sql
├── YYYYMMDD000006_swap_orders_detail_table.sql
└── YYYYMMDD000007_setup_pg_partman.sql               # 自動管理設定
```

---

## 4. 推奨実施順序

1. **staff_schedules を先に実施**（FK参照先でない・リスクが最も低い）
2. **orders を次に実施**（FK参照元は orders_detail, star_acquisitions のみ）
3. **orders_detail を最後に実施**（orders への FK 依存あり）
4. **アーカイブはパーティション化後**に実施（パーティション単位の DROP で完結）

---

## 5. 参考：パーティションプルーニング vs パーティションワイズ結合

| 最適化 | 説明 | 有効化条件 |
|--------|------|-----------|
| パーティションプルーニング | WHERE 句でパーティションを絞り込む | `enable_partition_pruning = on`（デフォルトon） |
| パーティションワイズ結合 | JOIN 対象の両テーブルが同じパーティション構成 | `enable_partitionwise_join = on`（デフォルトoff）+ 両テーブルが同じキー・境界 |

```sql
-- Supabase の postgresql.conf または接続時に設定
ALTER SYSTEM SET enable_partitionwise_join = on;
SELECT pg_reload_conf();

-- またはセッション単位
SET enable_partitionwise_join = on;
```
