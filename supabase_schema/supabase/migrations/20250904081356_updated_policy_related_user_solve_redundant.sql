drop policy "ユーザーは自分のメール設定のみ作成可能" on "public"."user_mail_settings";

drop policy "ユーザーは自分のメール設定のみ参照可能" on "public"."user_mail_settings";

drop policy "ユーザーは自分のメール設定のみ更新可能" on "public"."user_mail_settings";

drop policy "ユーザーは自分のプロフィール詳細のみ作成可" on "public"."user_profile_details";

drop policy "ユーザーは自分のプロフィール詳細のみ参照可" on "public"."user_profile_details";

drop policy "ユーザーは自分のプロフィール詳細のみ更新可" on "public"."user_profile_details";

create policy "user_mail_settings_access_policy"
on "public"."user_mail_settings"
as permissive
for all
to public
using ((( SELECT auth.uid() AS uid) = user_id))
with check ((( SELECT auth.uid() AS uid) = user_id));


create policy "user_mail_settings_deny_delete"
on "public"."user_mail_settings"
as permissive
for delete
to public
using (false);


create policy "user_profile_details_access_policy"
on "public"."user_profile_details"
as permissive
for all
to public
using ((( SELECT auth.uid() AS uid) = user_id))
with check ((( SELECT auth.uid() AS uid) = user_id));


create policy "user_profile_details_deny_delete"
on "public"."user_profile_details"
as permissive
for delete
to public
using (false);



