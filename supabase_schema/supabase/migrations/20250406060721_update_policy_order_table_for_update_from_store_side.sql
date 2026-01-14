drop policy "deny_all_orders" on "public"."orders";

drop policy "select_own_orders" on "public"."orders";

drop policy "update_own_orders" on "public"."orders";

create policy "select_own_or_store_orders"
on "public"."orders"
as permissive
for select
to public
using (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM store_profiles
  WHERE ((store_profiles.user_id = auth.uid()) AND (store_profiles.store_number = orders.store_number))))));


create policy "update_own_or_store_orders"
on "public"."orders"
as permissive
for update
to public
using (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM store_profiles
  WHERE ((store_profiles.user_id = auth.uid()) AND (store_profiles.store_number = orders.store_number))))));



