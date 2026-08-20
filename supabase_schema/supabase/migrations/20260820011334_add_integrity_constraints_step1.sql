-- ============================================================================
-- DB設計レビュー (Issue #938) Step 1: 低コストな整合性・一貫性の改善
--
-- アプリ改修を伴わず、既存データを壊さない範囲の修正のみを扱う。
-- 適用前にローカルDBの実データで違反ゼロを確認済み（18項目）。
-- リモート適用前にも同じ確認クエリを流すこと（Issue #938 のコメント参照）。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. 重複インデックスの削除
--    orders.order_id には UNIQUE 制約由来の orders_order_id_key が既にあり、
--    idx_orders_order_id は完全に同等。書き込みコストの純粋な二重払いになっている。
-- ----------------------------------------------------------------------------
drop index if exists "public"."idx_orders_order_id";

-- ----------------------------------------------------------------------------
-- 2. prefectures の RLS 有効化
--    public スキーマで唯一 RLS が無効だった。他のマスタ（categories / sizes /
--    stores / temperature_types）と同じ read-only ポリシーに揃える。
--    アプリ・RPC・ビューのいずれからも参照されていないため影響はない。
-- ----------------------------------------------------------------------------
alter table "public"."prefectures" enable row level security;

create policy "read_only_prefectures"
on "public"."prefectures"
as permissive
for select
to public
using (true);

-- ----------------------------------------------------------------------------
-- 3. orders_detail の外部キー列に NOT NULL
--    注文に紐づかない孤児明細を DB が許容していた。
--    同じ構造の carts_detail は当初から全列 NOT NULL であり、そちらに揃える。
-- ----------------------------------------------------------------------------
alter table "public"."orders_detail" alter column "order_id" set not null;
alter table "public"."orders_detail" alter column "user_id" set not null;
alter table "public"."orders_detail" alter column "product_id" set not null;
alter table "public"."orders_detail" alter column "temperature_type_id" set not null;
alter table "public"."orders_detail" alter column "size_id" set not null;

-- ----------------------------------------------------------------------------
-- 4. スター二重付与の防止
--    handle_star_acquisition() は 1 回の呼び出しで (order_id, category) の
--    1 行を insert する。リトライや二重実行で同じ注文・同じカテゴリの
--    スターが重複付与されるのを DB 側で塞ぐ。
--    副次効果として、FK 列 order_id の索引も復活する
--    （20260310000001 で idx_star_acquisitions_order_id を削除済みだった）。
-- ----------------------------------------------------------------------------
create unique index star_acquisitions_order_id_category_key
  on public.star_acquisitions using btree (order_id, category);

alter table "public"."star_acquisitions"
  add constraint "star_acquisitions_order_id_category_key"
  unique using index "star_acquisitions_order_id_category_key";

-- ----------------------------------------------------------------------------
-- 5. メインカードの一意性
--    「1ユーザーにつきメインカードは1枚」がどこにも保証されていなかった。
--    is_main は integer（0/1）のため部分ユニークインデックスで表現する。
--    ※ is_main の boolean 化は Step 2 で扱う。
-- ----------------------------------------------------------------------------
create unique index cards_user_id_is_main_key
  on public.cards using btree (user_id)
  where (is_main = 1);

-- ----------------------------------------------------------------------------
-- 6. 金額・数量・座標の CHECK 制約
--    これまで CHECK は card_id の書式・email の書式・区分値の列挙のみで、
--    金額系・数量系には一切かかっていなかった。
-- ----------------------------------------------------------------------------

-- 残高は負にならない
alter table "public"."cards"
  add constraint "cards_balance_non_negative" check ((balance >= 0)) not valid;
alter table "public"."cards" validate constraint "cards_balance_non_negative";

-- 注文金額は負にならず、税込は税抜を下回らない
alter table "public"."orders"
  add constraint "orders_price_without_tax_non_negative" check ((price_without_tax >= 0)) not valid;
alter table "public"."orders" validate constraint "orders_price_without_tax_non_negative";

alter table "public"."orders"
  add constraint "orders_price_with_tax_gte_without_tax" check ((price_with_tax >= price_without_tax)) not valid;
alter table "public"."orders" validate constraint "orders_price_with_tax_gte_without_tax";

-- 明細の数量は 1 以上、小計は負にならない
alter table "public"."orders_detail"
  add constraint "orders_detail_count_positive" check ((count > 0)) not valid;
alter table "public"."orders_detail" validate constraint "orders_detail_count_positive";

alter table "public"."orders_detail"
  add constraint "orders_detail_subtotal_non_negative" check ((subtotal_without_tax >= 0)) not valid;
alter table "public"."orders_detail" validate constraint "orders_detail_subtotal_non_negative";

alter table "public"."carts_detail"
  add constraint "carts_detail_count_positive" check ((count > 0)) not valid;
alter table "public"."carts_detail" validate constraint "carts_detail_count_positive";

alter table "public"."carts_detail"
  add constraint "carts_detail_subtotal_non_negative" check ((subtotal_without_tax >= 0)) not valid;
alter table "public"."carts_detail" validate constraint "carts_detail_subtotal_non_negative";

-- 商品価格は負にならない
alter table "public"."product_sizes"
  add constraint "product_sizes_price_non_negative" check ((price >= 0)) not valid;
alter table "public"."product_sizes" validate constraint "product_sizes_price_non_negative";

-- スターのポイントは負にならない
alter table "public"."star_acquisitions"
  add constraint "star_acquisitions_points_non_negative" check ((acquired_points >= 0)) not valid;
alter table "public"."star_acquisitions" validate constraint "star_acquisitions_points_non_negative";

alter table "public"."star_usage"
  add constraint "star_usage_point_used_non_negative" check ((point_used >= 0)) not valid;
alter table "public"."star_usage" validate constraint "star_usage_point_used_non_negative";

alter table "public"."star_aggregations"
  add constraint "star_aggregations_total_points_non_negative" check ((total_points >= 0)) not valid;
alter table "public"."star_aggregations" validate constraint "star_aggregations_total_points_non_negative";

-- 緯度経度は地理座標の範囲内
--   ※ DEFAULT 0.0 の是非（(0,0) が実在座標である問題）は Step 2 以降で扱う
alter table "public"."stores"
  add constraint "stores_latitude_range" check (((latitude >= (-90)::double precision) and (latitude <= (90)::double precision))) not valid;
alter table "public"."stores" validate constraint "stores_latitude_range";

alter table "public"."stores"
  add constraint "stores_longitude_range" check (((longitude >= (-180)::double precision) and (longitude <= (180)::double precision))) not valid;
alter table "public"."stores" validate constraint "stores_longitude_range";

-- ----------------------------------------------------------------------------
-- 7. updated_at 自動更新トリガの統一
--    updated_at 列を持つのに更新トリガが無いテーブルが多数あり、
--    アプリが明示的にセットしない限り created_at のまま固定されていた。
--    差分同期・キャッシュ無効化の基準として使えるようにする。
--
--    関数は update_updated_at_column() に統一する
--    （update_timestamp() と実装は同一。既存トリガの張り替えは行わない）。
--
--    アーカイブ3テーブル（orders_archive / star_acquisitions_archive /
--    star_usage_archive）は退避元の updated_at をそのまま保持する必要があるため
--    意図的に対象外とする。
-- ----------------------------------------------------------------------------
create trigger update_campaign_settings_updated_at
  before update on public.campaign_settings
  for each row execute function public.update_updated_at_column();

create trigger update_carts_updated_at
  before update on public.carts
  for each row execute function public.update_updated_at_column();

create trigger update_categories_updated_at
  before update on public.categories
  for each row execute function public.update_updated_at_column();

create trigger update_products_updated_at
  before update on public.products
  for each row execute function public.update_updated_at_column();

create trigger update_star_acquisitions_updated_at
  before update on public.star_acquisitions
  for each row execute function public.update_updated_at_column();

create trigger update_star_aggregations_updated_at
  before update on public.star_aggregations
  for each row execute function public.update_updated_at_column();

create trigger update_store_profiles_updated_at
  before update on public.store_profiles
  for each row execute function public.update_updated_at_column();

create trigger update_stores_updated_at
  before update on public.stores
  for each row execute function public.update_updated_at_column();

create trigger update_user_fcm_tokens_updated_at
  before update on public.user_fcm_tokens
  for each row execute function public.update_updated_at_column();

create trigger update_user_tickets_updated_at
  before update on public.user_tickets
  for each row execute function public.update_updated_at_column();
