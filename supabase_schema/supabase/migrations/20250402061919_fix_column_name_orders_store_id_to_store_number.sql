-- ポリシーを削除
drop policy "店舗は自分の注文のみ閲覧可能" on "public"."orders";
drop policy "店舗は自分の注文詳細のみ閲覧可能" on "public"."orders_detail";

-- 外部キー制約を削除
alter table "public"."orders" drop constraint "orders_store_id_fkey";

-- インデックスを削除
drop index if exists "public"."idx_orders_store_id";

-- まず、NULL許容のstore_numberカラムを追加
alter table "public"."orders" add column "store_number" character(4);

-- 既存のstore_idからstore_numberへデータをコピー
update "public"."orders" set "store_number" = "store_id";

-- NOT NULL制約を追加
alter table "public"."orders" alter column "store_number" set not null;

-- 古いカラムを削除
alter table "public"."orders" drop column "store_id";

-- 新しいインデックスを作成
CREATE INDEX idx_orders_store_number ON public.orders USING btree (store_number);

-- 外部キー制約を追加
alter table "public"."orders" add constraint "orders_store_number_fkey" FOREIGN KEY (store_number) REFERENCES stores(store_number) not valid;
alter table "public"."orders" validate constraint "orders_store_number_fkey";

-- ポリシーを再作成
create policy "店舗は自分の注文のみ閲覧可能"
on "public"."orders"
as permissive
for select
to public
using ((EXISTS ( SELECT 1
   FROM store_profiles
  WHERE ((store_profiles.user_id = auth.uid()) AND (store_profiles.store_number = orders.store_number)))));

create policy "店舗は自分の注文詳細のみ閲覧可能"
on "public"."orders_detail"
as permissive
for select
to public
using ((EXISTS ( SELECT 1
   FROM (orders o
     JOIN store_profiles sp ON ((o.store_number = sp.store_number)))
  WHERE ((sp.user_id = auth.uid()) AND ((o.order_id)::text = (orders_detail.order_id)::text)))));