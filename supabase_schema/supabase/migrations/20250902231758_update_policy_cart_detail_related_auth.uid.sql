drop policy "Delete policy for carts_detail" on "public"."carts_detail";

drop policy "Select policy for carts_detail" on "public"."carts_detail";

drop policy "Update policy for carts_detail" on "public"."carts_detail";

create policy "Delete policy for carts_detail"
on "public"."carts_detail"
as permissive
for delete
to authenticated
using ((( SELECT auth.uid() AS uid) = user_id));


create policy "Select policy for carts_detail"
on "public"."carts_detail"
as permissive
for select
to authenticated
using ((( SELECT auth.uid() AS uid) = user_id));


create policy "Update policy for carts_detail"
on "public"."carts_detail"
as permissive
for update
to authenticated
using ((( SELECT auth.uid() AS uid) = user_id));



