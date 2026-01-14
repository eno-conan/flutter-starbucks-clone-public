create table "public"."pre_signup_users" (
    "id" uuid not null default gen_random_uuid(),
    "token" text not null,
    "email" text not null,
    "created_at" timestamp with time zone not null default now(),
    "expires_at" timestamp with time zone not null
);


alter table "public"."pre_signup_users" enable row level security;

CREATE INDEX pre_signup_users_email_idx ON public.pre_signup_users USING btree (email);

CREATE UNIQUE INDEX pre_signup_users_pkey ON public.pre_signup_users USING btree (id);

CREATE UNIQUE INDEX pre_signup_users_token_idx ON public.pre_signup_users USING btree (token);

alter table "public"."pre_signup_users" add constraint "pre_signup_users_pkey" PRIMARY KEY using index "pre_signup_users_pkey";

alter table "public"."pre_signup_users" add constraint "pre_signup_users_email_check" CHECK ((char_length(email) <= 128)) not valid;

alter table "public"."pre_signup_users" validate constraint "pre_signup_users_email_check";

alter table "public"."pre_signup_users" add constraint "pre_signup_users_token_check" CHECK ((char_length(token) = 32)) not valid;

alter table "public"."pre_signup_users" validate constraint "pre_signup_users_token_check";

alter table "public"."pre_signup_users" add constraint "valid_email" CHECK ((email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)) not valid;

alter table "public"."pre_signup_users" validate constraint "valid_email";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.set_expires_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.expires_at = NEW.created_at + INTERVAL '30 minutes';
  RETURN NEW;
END;
$function$
;

grant delete on table "public"."pre_signup_users" to "anon";

grant insert on table "public"."pre_signup_users" to "anon";

grant references on table "public"."pre_signup_users" to "anon";

grant select on table "public"."pre_signup_users" to "anon";

grant trigger on table "public"."pre_signup_users" to "anon";

grant truncate on table "public"."pre_signup_users" to "anon";

grant update on table "public"."pre_signup_users" to "anon";

grant delete on table "public"."pre_signup_users" to "authenticated";

grant insert on table "public"."pre_signup_users" to "authenticated";

grant references on table "public"."pre_signup_users" to "authenticated";

grant select on table "public"."pre_signup_users" to "authenticated";

grant trigger on table "public"."pre_signup_users" to "authenticated";

grant truncate on table "public"."pre_signup_users" to "authenticated";

grant update on table "public"."pre_signup_users" to "authenticated";

grant delete on table "public"."pre_signup_users" to "service_role";

grant insert on table "public"."pre_signup_users" to "service_role";

grant references on table "public"."pre_signup_users" to "service_role";

grant select on table "public"."pre_signup_users" to "service_role";

grant trigger on table "public"."pre_signup_users" to "service_role";

grant truncate on table "public"."pre_signup_users" to "service_role";

grant update on table "public"."pre_signup_users" to "service_role";

create policy "deny_all"
on "public"."pre_signup_users"
as permissive
for all
to public
using (false);


create policy "insert_policy"
on "public"."pre_signup_users"
as permissive
for insert
to public
with check (true);


create policy "no_delete"
on "public"."pre_signup_users"
as permissive
for delete
to public
using (false);


create policy "no_update"
on "public"."pre_signup_users"
as permissive
for update
to public
using (false);


create policy "select_if_email_matches"
on "public"."pre_signup_users"
as permissive
for select
to public
using (((auth.jwt() ->> 'email'::text) = email));


CREATE TRIGGER set_pre_signup_users_expires_at BEFORE INSERT ON public.pre_signup_users FOR EACH ROW EXECUTE FUNCTION set_expires_at();


