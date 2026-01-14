create table "public"."user_fcm_tokens" (
    "id" uuid not null,
    "fcm_token" text
);


alter table "public"."user_fcm_tokens" enable row level security;

CREATE UNIQUE INDEX user_fcm_tokens_pkey ON public.user_fcm_tokens USING btree (id);

alter table "public"."user_fcm_tokens" add constraint "user_fcm_tokens_pkey" PRIMARY KEY using index "user_fcm_tokens_pkey";

alter table "public"."user_fcm_tokens" add constraint "user_fcm_tokens_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) not valid;

alter table "public"."user_fcm_tokens" validate constraint "user_fcm_tokens_id_fkey";

grant delete on table "public"."user_fcm_tokens" to "anon";

grant insert on table "public"."user_fcm_tokens" to "anon";

grant references on table "public"."user_fcm_tokens" to "anon";

grant select on table "public"."user_fcm_tokens" to "anon";

grant trigger on table "public"."user_fcm_tokens" to "anon";

grant truncate on table "public"."user_fcm_tokens" to "anon";

grant update on table "public"."user_fcm_tokens" to "anon";

grant delete on table "public"."user_fcm_tokens" to "authenticated";

grant insert on table "public"."user_fcm_tokens" to "authenticated";

grant references on table "public"."user_fcm_tokens" to "authenticated";

grant select on table "public"."user_fcm_tokens" to "authenticated";

grant trigger on table "public"."user_fcm_tokens" to "authenticated";

grant truncate on table "public"."user_fcm_tokens" to "authenticated";

grant update on table "public"."user_fcm_tokens" to "authenticated";

grant delete on table "public"."user_fcm_tokens" to "service_role";

grant insert on table "public"."user_fcm_tokens" to "service_role";

grant references on table "public"."user_fcm_tokens" to "service_role";

grant select on table "public"."user_fcm_tokens" to "service_role";

grant trigger on table "public"."user_fcm_tokens" to "service_role";

grant truncate on table "public"."user_fcm_tokens" to "service_role";

grant update on table "public"."user_fcm_tokens" to "service_role";

create policy "Allow users to do everything on their own fcm_token"
on "public"."user_fcm_tokens"
as permissive
for all
to public
using ((auth.uid() = id))
with check ((auth.uid() = id));



