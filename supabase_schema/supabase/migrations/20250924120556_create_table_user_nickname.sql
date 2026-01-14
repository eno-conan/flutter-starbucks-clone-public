create table "public"."user_nickname" (
    "user_id" uuid not null,
    "nick_name" text not null
);


alter table "public"."user_nickname" enable row level security;

CREATE UNIQUE INDEX user_nickname_pkey ON public.user_nickname USING btree (user_id);

alter table "public"."user_nickname" add constraint "user_nickname_pkey" PRIMARY KEY using index "user_nickname_pkey";

alter table "public"."user_nickname" add constraint "user_nickname_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_nickname" validate constraint "user_nickname_user_id_fkey";

grant delete on table "public"."user_nickname" to "anon";

grant insert on table "public"."user_nickname" to "anon";

grant references on table "public"."user_nickname" to "anon";

grant select on table "public"."user_nickname" to "anon";

grant trigger on table "public"."user_nickname" to "anon";

grant truncate on table "public"."user_nickname" to "anon";

grant update on table "public"."user_nickname" to "anon";

grant delete on table "public"."user_nickname" to "authenticated";

grant insert on table "public"."user_nickname" to "authenticated";

grant references on table "public"."user_nickname" to "authenticated";

grant select on table "public"."user_nickname" to "authenticated";

grant trigger on table "public"."user_nickname" to "authenticated";

grant truncate on table "public"."user_nickname" to "authenticated";

grant update on table "public"."user_nickname" to "authenticated";

grant delete on table "public"."user_nickname" to "service_role";

grant insert on table "public"."user_nickname" to "service_role";

grant references on table "public"."user_nickname" to "service_role";

grant select on table "public"."user_nickname" to "service_role";

grant trigger on table "public"."user_nickname" to "service_role";

grant truncate on table "public"."user_nickname" to "service_role";

grant update on table "public"."user_nickname" to "service_role";

create policy "ユーザーは自分のニックネームのみ削除可能"
on "public"."user_nickname"
as permissive
for delete
to authenticated
using ((auth.uid() = user_id));


create policy "ユーザーは自分のニックネームのみ参照可能"
on "public"."user_nickname"
as permissive
for select
to authenticated
using ((auth.uid() = user_id));


create policy "ユーザーは自分のニックネームのみ更新可能"
on "public"."user_nickname"
as permissive
for update
to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "ユーザーは自分のニックネームのみ登録可能"
on "public"."user_nickname"
as permissive
for insert
to authenticated
with check ((auth.uid() = user_id));



