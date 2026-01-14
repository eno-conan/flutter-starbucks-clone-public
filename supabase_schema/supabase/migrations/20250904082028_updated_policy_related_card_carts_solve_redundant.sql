drop policy "ユーザーは自分のIDでのみカードを作成可能" on "public"."cards";

drop policy "ユーザーは自分のカードデータのみ削除可能" on "public"."cards";

drop policy "ユーザーは自分のカードデータのみ参照可能" on "public"."cards";

drop policy "ユーザーは自分のカードデータのみ更新可能" on "public"."cards";

drop policy "ユーザーは自分のカートのみ削除可能" on "public"."carts";

drop policy "ユーザーは自分のカートのみ更新可能" on "public"."carts";

drop policy "ユーザーは自分のカートのみ閲覧可能" on "public"."carts";

create policy "cards_access_policy"
on "public"."cards"
as permissive
for all
to public
using ((( SELECT auth.uid() AS uid) = user_id))
with check ((( SELECT auth.uid() AS uid) = user_id));


create policy "ユーザーは自分のカートのみ削除可能"
on "public"."carts"
as permissive
for delete
to authenticated
using ((( SELECT auth.uid() AS uid) = user_id));


create policy "ユーザーは自分のカートのみ更新可能"
on "public"."carts"
as permissive
for update
to authenticated
using ((( SELECT auth.uid() AS uid) = user_id));


create policy "ユーザーは自分のカートのみ閲覧可能"
on "public"."carts"
as permissive
for select
to authenticated
using ((( SELECT auth.uid() AS uid) = user_id));



