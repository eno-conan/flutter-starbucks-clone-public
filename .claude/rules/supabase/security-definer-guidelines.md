---
description: SECURITY DEFINERガイドライン（RLSバイパス・PostgreSQL関数セキュリティ）
paths:
  - "supabase_schema/**/*.sql"
  - "supabase_schema/**/*.md"
---

# SECURITY DEFINER ガイドライン

## 📋 概要

このドキュメントは、Supabase/PostgreSQL における `SECURITY DEFINER` の挙動・
RLS との関係・本プロジェクトでの利用方針をまとめたリファレンスです。

---

## 1. SECURITY DEFINER とは

PostgreSQL の関数には、**実行時にどのユーザーの権限で動かすか**を指定できる。

| オプション | 実行権限 | デフォルト |
|---|---|---|
| `SECURITY INVOKER` | 関数を**呼び出したユーザー**の権限で実行 | ✅ デフォルト |
| `SECURITY DEFINER` | 関数を**定義したユーザー**の権限で実行 | — |

Supabase では関数を `service_role`（スーパーユーザー相当）で作成するため、
`SECURITY DEFINER` を付けると RLS を含めた全アクセス制御をバイパスして実行される。

---

## 2. RLS との関係

### なぜ RLS をバイパスするか

Row Level Security (RLS) は「呼び出し元ユーザーの JWT」を基に行を絞り込む。
`SECURITY DEFINER` では呼び出し元ではなく定義者（`service_role`）として実行されるため、
JWT に依存した RLS ポリシーが適用されない。

### バイパスが安全な理由

RLS バイパスは「内部の全行データが見える」という意味ではなく、
**関数の SQL 本体が返すカラム・行だけが呼び出し元に届く**。
返却データを集計値・公開可能な項目のみに限定すれば、
内部データ（個人情報・未公開情報）は呼び出し元に渡らない。

```
呼び出し元 (anon / authenticated)
    │
    ▼
RPC 関数 (SECURITY DEFINER)
    │  ← ここで RLS をバイパスして全行を参照できる
    │  ← ただし SELECT するカラムは設計者が明示的に制御する
    ▼
返却データ（集計値・公開カラムのみ）
    │
    ▼
呼び出し元が受け取るのはこのデータだけ
```

---

## 3. 本プロジェクトでの使用例

### `get_store_wait_times`

**場所**: `supabase_schema/supabase/migrations/20260220130656_updated_rpc_get_store_wait_times.sql`

**目的**: 現在時刻の時間帯に基づき、各店舗のスタッフ数・準備中アイテム数を集計して返す。

**なぜ SECURITY DEFINER が必要か**:
- `staff_schedules`, `staff`, `orders`, `orders_detail` テーブルは
  店舗運営データであり、一般ユーザーが直接参照してはいけない。
- RLS が有効になっていると `anon` / `authenticated` ロールからは行が取得できない。
- 集計結果（スタッフ数・アイテム数）だけを公開したいため、
  `SECURITY DEFINER` で関数内部で全行を読み取り、集計値のみを返却する。

**返却データ（公開してよい情報のみ）**:

```sql
SELECT
    sc.store_number,       -- 店舗番号
    sc.total_staff,        -- 総スタッフ数（集計値）
    sc.cooking_staff,      -- 調理担当スタッフ数（集計値）
    COALESCE(pi.total_items, 0) AS preparing_items,  -- 準備中アイテム数（集計値）
    (SELECT period_name FROM current_period) IS NOT NULL AS is_open  -- 営業中フラグ
FROM staff_counts sc
LEFT JOIN preparing_items pi ON sc.store_number = pi.store_number;
```

個人を特定できる情報（スタッフ名、注文者情報など）は一切返却していない。

**SQL 定義の構造**:

```sql
CREATE OR REPLACE FUNCTION public.get_store_wait_times(p_date date)
 RETURNS TABLE(store_number text, total_staff integer, cooking_staff integer,
               preparing_items integer, is_open boolean)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'   -- ← セキュリティ強化のために必須
AS $function$
  -- 集計ロジック
$function$;
```

---

## 4. 使用すべきケース / 避けるべきケース

### ✅ 使用すべきケース

- **集計・統計情報の公開**: 内部テーブルを集計した結果だけを返す場合
  - 例: スタッフ数合計、待ち時間指標、在庫数合計
- **クロステーブル集計**: RLS で保護された複数テーブルを JOIN して集計する場合
- **ビジネスロジックのカプセル化**: 複雑なロジックを安全に実行し、最小限の結果を返す場合

### ❌ 避けるべきケース

- **個人情報・機密データの返却**: スタッフ名・メールアドレス・住所などを含む行をそのまま返す場合
- **呼び出し元ユーザーの所有データ取得**: RLS でユーザー自身のデータを絞り込む場合は `SECURITY INVOKER` が適切
- **デバッグ目的の一時的なバイパス**: 本番コードでは使用しない
- **広範な SELECT の委譲**: `SELECT *` を返すような関数は内部データが漏洩するリスクがある

---

## 5. セキュリティチェックリスト

新たに `SECURITY DEFINER` を使う関数を作成・変更する際は以下を確認すること。

### 必須チェック

- [ ] **`SET search_path TO 'public'`** を関数定義に含めているか
  - 指定しないと悪意あるスキーマへの `search_path hijacking` 攻撃が可能になる
  - Supabase の linter でも警告対象となる

- [ ] **返却カラムは集計値または公開可能な情報のみ**か
  - `SELECT *` や個人情報カラムを返していないこと

- [ ] **引数バリデーション**が実装されているか
  - SQL インジェクションの余地がないこと（プレースホルダー使用）

- [ ] **Supabase Dashboard の `exposed` 設定**を確認したか
  - Dashboard > Database > Functions で `Exposed in API` の状態を確認
  - 不要な関数を公開しないこと

### 推奨チェック

- [ ] 関数のコメントに「なぜ SECURITY DEFINER が必要か」を記載しているか
- [ ] `RETURNS TABLE(...)` で返却カラムを明示的に定義しているか
  - `RETURNS SETOF <table>` はテーブルの全カラムが返るため避ける
- [ ] マイグレーションに `drop function if exists` を含めているか（再作成時の冪等性）

---

## 6. `SET search_path TO 'public'` の必要性

`SECURITY DEFINER` 関数は定義者の権限で実行されるため、
`search_path` を攻撃者に操作されると意図しないオブジェクトを参照させられる
（**Search Path Hijacking**）。

```sql
-- ❌ 危険: search_path 未指定
CREATE FUNCTION public.my_func()
RETURNS TABLE(...) LANGUAGE sql SECURITY DEFINER
AS $$ SELECT ... FROM staff_schedules; $$;

-- ✅ 安全: 明示的に 'public' を指定
CREATE FUNCTION public.my_func()
RETURNS TABLE(...) LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'   -- ← これが必要
AS $$ SELECT ... FROM staff_schedules; $$;
```

Supabase の PostgreSQL Linter (`plpgsql_check` 等) はこの欠落を警告するため、
新規関数には必ず付与すること。

---

## 📚 参考資料

- [PostgreSQL: CREATE FUNCTION - SECURITY](https://www.postgresql.org/docs/current/sql-createfunction.html)
- [Supabase: Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase: Database Functions](https://supabase.com/docs/guides/database/functions)
- [OWASP: SQL Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
