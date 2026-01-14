drop policy "Allow users to do everything on their own fcm_token" on "public"."user_fcm_tokens";

alter table "public"."user_fcm_tokens" drop constraint "user_fcm_tokens_id_fkey";

alter table "public"."user_fcm_tokens" drop constraint "user_fcm_tokens_pkey";

drop index if exists "public"."user_fcm_tokens_pkey";

alter table "public"."user_fcm_tokens" drop column "id";

alter table "public"."user_fcm_tokens" add column "user_id" uuid not null;

CREATE UNIQUE INDEX user_fcm_tokens_user_id_pkey ON public.user_fcm_tokens USING btree (user_id);

alter table "public"."user_fcm_tokens" add constraint "user_fcm_tokens_user_id_pkey" PRIMARY KEY using index "user_fcm_tokens_user_id_pkey";

alter table "public"."user_fcm_tokens" add constraint "user_fcm_tokens_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."user_fcm_tokens" validate constraint "user_fcm_tokens_user_id_fkey";

create policy "Allow users to do everything on their own fcm_token"
on "public"."user_fcm_tokens"
as permissive
for all
to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



