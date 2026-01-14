create table "public"."user_mail_settings" (
    "id" uuid not null default uuid_generate_v4(),
    "user_id" uuid not null,
    "is_send_related_rewards" integer not null default 0,
    "is_send_advance_product_announce" integer not null default 0,
    "is_html_mail" integer not null default 1,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
);


alter table "public"."user_mail_settings" enable row level security;

create table "public"."user_profile_details" (
    "id" uuid not null default uuid_generate_v4(),
    "user_id" uuid not null,
    "birthday" text,
    "sex" integer,
    "tele_num" text,
    "postal_code" text,
    "prefecture_id" integer,
    "address1" text,
    "address2" text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
);


alter table "public"."user_profile_details" enable row level security;

CREATE UNIQUE INDEX user_mail_settings_pkey ON public.user_mail_settings USING btree (id);

CREATE UNIQUE INDEX user_mail_settings_user_id_key ON public.user_mail_settings USING btree (user_id);

CREATE UNIQUE INDEX user_profile_details_pkey ON public.user_profile_details USING btree (id);

CREATE UNIQUE INDEX user_profile_details_user_id_key ON public.user_profile_details USING btree (user_id);

alter table "public"."user_mail_settings" add constraint "user_mail_settings_pkey" PRIMARY KEY using index "user_mail_settings_pkey";

alter table "public"."user_profile_details" add constraint "user_profile_details_pkey" PRIMARY KEY using index "user_profile_details_pkey";

alter table "public"."user_mail_settings" add constraint "user_mail_settings_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_mail_settings" validate constraint "user_mail_settings_user_id_fkey";

alter table "public"."user_mail_settings" add constraint "user_mail_settings_user_id_key" UNIQUE using index "user_mail_settings_user_id_key";

alter table "public"."user_profile_details" add constraint "user_profile_details_prefecture_id_fkey" FOREIGN KEY (prefecture_id) REFERENCES prefectures(id) not valid;

alter table "public"."user_profile_details" validate constraint "user_profile_details_prefecture_id_fkey";

alter table "public"."user_profile_details" add constraint "user_profile_details_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_profile_details" validate constraint "user_profile_details_user_id_fkey";

alter table "public"."user_profile_details" add constraint "user_profile_details_user_id_key" UNIQUE using index "user_profile_details_user_id_key";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.update_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$
;

grant delete on table "public"."user_mail_settings" to "anon";

grant insert on table "public"."user_mail_settings" to "anon";

grant references on table "public"."user_mail_settings" to "anon";

grant select on table "public"."user_mail_settings" to "anon";

grant trigger on table "public"."user_mail_settings" to "anon";

grant truncate on table "public"."user_mail_settings" to "anon";

grant update on table "public"."user_mail_settings" to "anon";

grant delete on table "public"."user_mail_settings" to "authenticated";

grant insert on table "public"."user_mail_settings" to "authenticated";

grant references on table "public"."user_mail_settings" to "authenticated";

grant select on table "public"."user_mail_settings" to "authenticated";

grant trigger on table "public"."user_mail_settings" to "authenticated";

grant truncate on table "public"."user_mail_settings" to "authenticated";

grant update on table "public"."user_mail_settings" to "authenticated";

grant delete on table "public"."user_mail_settings" to "service_role";

grant insert on table "public"."user_mail_settings" to "service_role";

grant references on table "public"."user_mail_settings" to "service_role";

grant select on table "public"."user_mail_settings" to "service_role";

grant trigger on table "public"."user_mail_settings" to "service_role";

grant truncate on table "public"."user_mail_settings" to "service_role";

grant update on table "public"."user_mail_settings" to "service_role";

grant delete on table "public"."user_profile_details" to "anon";

grant insert on table "public"."user_profile_details" to "anon";

grant references on table "public"."user_profile_details" to "anon";

grant select on table "public"."user_profile_details" to "anon";

grant trigger on table "public"."user_profile_details" to "anon";

grant truncate on table "public"."user_profile_details" to "anon";

grant update on table "public"."user_profile_details" to "anon";

grant delete on table "public"."user_profile_details" to "authenticated";

grant insert on table "public"."user_profile_details" to "authenticated";

grant references on table "public"."user_profile_details" to "authenticated";

grant select on table "public"."user_profile_details" to "authenticated";

grant trigger on table "public"."user_profile_details" to "authenticated";

grant truncate on table "public"."user_profile_details" to "authenticated";

grant update on table "public"."user_profile_details" to "authenticated";

grant delete on table "public"."user_profile_details" to "service_role";

grant insert on table "public"."user_profile_details" to "service_role";

grant references on table "public"."user_profile_details" to "service_role";

grant select on table "public"."user_profile_details" to "service_role";

grant trigger on table "public"."user_profile_details" to "service_role";

grant truncate on table "public"."user_profile_details" to "service_role";

grant update on table "public"."user_profile_details" to "service_role";

create policy "ユーザーは自分のメール設定のみ作成可能"
on "public"."user_mail_settings"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "ユーザーは自分のメール設定のみ参照可能"
on "public"."user_mail_settings"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "ユーザーは自分のメール設定のみ更新可能"
on "public"."user_mail_settings"
as permissive
for update
to public
using ((auth.uid() = user_id));


create policy "ユーザーは自分のプロフィール詳細のみ作成可"
on "public"."user_profile_details"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "ユーザーは自分のプロフィール詳細のみ参照可"
on "public"."user_profile_details"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "ユーザーは自分のプロフィール詳細のみ更新可"
on "public"."user_profile_details"
as permissive
for update
to public
using ((auth.uid() = user_id));


CREATE TRIGGER update_user_mail_settings_timestamp BEFORE UPDATE ON public.user_mail_settings FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_user_profile_details_timestamp BEFORE UPDATE ON public.user_profile_details FOR EACH ROW EXECUTE FUNCTION update_timestamp();


