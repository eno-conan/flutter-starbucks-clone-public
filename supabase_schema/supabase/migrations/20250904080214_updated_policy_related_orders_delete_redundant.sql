drop policy "select_own_or_store_orders" on "public"."orders";

drop policy "店舗は自分の注文のみ閲覧可能" on "public"."orders";

drop policy "Allow select for authenticated users only" on "public"."orders_detail";

drop policy "店舗は自分の注文詳細のみ閲覧可能" on "public"."orders_detail";

create policy "orders_access_policy"
on "public"."orders"
as permissive
for select
to public
using (((( SELECT auth.uid() AS uid) = user_id) OR (EXISTS ( SELECT 1
   FROM store_profiles
  WHERE ((store_profiles.user_id = ( SELECT auth.uid() AS uid)) AND (store_profiles.store_number = orders.store_number))))));


create policy "orders_detail_access_policy"
on "public"."orders_detail"
as permissive
for select
to public
using (((( SELECT auth.uid() AS uid) = user_id) OR (EXISTS ( SELECT 1
   FROM (orders o
     JOIN store_profiles sp ON ((o.store_number = sp.store_number)))
  WHERE ((sp.user_id = ( SELECT auth.uid() AS uid)) AND ((o.order_id)::text = (orders_detail.order_id)::text))))));



