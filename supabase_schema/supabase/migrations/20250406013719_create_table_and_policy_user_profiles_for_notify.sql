create table "public"."user_profiles" (
    "id" uuid not null,
    "fcm_token" text
);


alter table "public"."user_profiles" enable row level security;

CREATE UNIQUE INDEX user_profiles_pkey ON public.user_profiles USING btree (id);

alter table "public"."user_profiles" add constraint "user_profiles_pkey" PRIMARY KEY using index "user_profiles_pkey";

alter table "public"."user_profiles" add constraint "user_profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) not valid;

alter table "public"."user_profiles" validate constraint "user_profiles_id_fkey";

grant delete on table "public"."user_profiles" to "anon";

grant insert on table "public"."user_profiles" to "anon";

grant references on table "public"."user_profiles" to "anon";

grant select on table "public"."user_profiles" to "anon";

grant trigger on table "public"."user_profiles" to "anon";

grant truncate on table "public"."user_profiles" to "anon";

grant update on table "public"."user_profiles" to "anon";

grant delete on table "public"."user_profiles" to "authenticated";

grant insert on table "public"."user_profiles" to "authenticated";

grant references on table "public"."user_profiles" to "authenticated";

grant select on table "public"."user_profiles" to "authenticated";

grant trigger on table "public"."user_profiles" to "authenticated";

grant truncate on table "public"."user_profiles" to "authenticated";

grant update on table "public"."user_profiles" to "authenticated";

grant delete on table "public"."user_profiles" to "service_role";

grant insert on table "public"."user_profiles" to "service_role";

grant references on table "public"."user_profiles" to "service_role";

grant select on table "public"."user_profiles" to "service_role";

grant trigger on table "public"."user_profiles" to "service_role";

grant truncate on table "public"."user_profiles" to "service_role";

grant update on table "public"."user_profiles" to "service_role";

create policy "ユーザーは自分のプロフィールのみ削除可能"
on "public"."user_profiles"
as permissive
for delete
to authenticated
using ((auth.uid() = id));


create policy "ユーザーは自分のプロフィールのみ参照可能"
on "public"."user_profiles"
as permissive
for select
to authenticated
using ((auth.uid() = id));


create policy "ユーザーは自分のプロフィールのみ更新可能"
on "public"."user_profiles"
as permissive
for update
to authenticated
using ((auth.uid() = id));


create policy "認証済みユーザーはプロフィールを作成可能"
on "public"."user_profiles"
as permissive
for insert
to authenticated
with check ((auth.uid() = id));



