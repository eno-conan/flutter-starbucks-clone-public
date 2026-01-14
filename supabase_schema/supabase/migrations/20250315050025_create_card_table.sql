create table "public"."cards" (
    "id" uuid not null default gen_random_uuid(),
    "card_id" text not null,
    "user_id" uuid not null,
    "card_name" text not null,
    "image_url" text,
    "balance" integer default 0,
    "is_main" integer default 0,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
);


alter table "public"."cards" enable row level security;

CREATE UNIQUE INDEX cards_pkey ON public.cards USING btree (id);

CREATE INDEX idx_cards_card_id ON public.cards USING btree (card_id);

CREATE INDEX idx_cards_user_id ON public.cards USING btree (user_id);

CREATE UNIQUE INDEX unique_card_id ON public.cards USING btree (card_id);

alter table "public"."cards" add constraint "cards_pkey" PRIMARY KEY using index "cards_pkey";

alter table "public"."cards" add constraint "cards_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."cards" validate constraint "cards_user_id_fkey";

alter table "public"."cards" add constraint "unique_card_id" UNIQUE using index "unique_card_id";

alter table "public"."cards" add constraint "valid_card_id" CHECK ((card_id ~ '^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}$'::text)) not valid;

alter table "public"."cards" validate constraint "valid_card_id";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$
;

grant delete on table "public"."cards" to "anon";

grant insert on table "public"."cards" to "anon";

grant references on table "public"."cards" to "anon";

grant select on table "public"."cards" to "anon";

grant trigger on table "public"."cards" to "anon";

grant truncate on table "public"."cards" to "anon";

grant update on table "public"."cards" to "anon";

grant delete on table "public"."cards" to "authenticated";

grant insert on table "public"."cards" to "authenticated";

grant references on table "public"."cards" to "authenticated";

grant select on table "public"."cards" to "authenticated";

grant trigger on table "public"."cards" to "authenticated";

grant truncate on table "public"."cards" to "authenticated";

grant update on table "public"."cards" to "authenticated";

grant delete on table "public"."cards" to "service_role";

grant insert on table "public"."cards" to "service_role";

grant references on table "public"."cards" to "service_role";

grant select on table "public"."cards" to "service_role";

grant trigger on table "public"."cards" to "service_role";

grant truncate on table "public"."cards" to "service_role";

grant update on table "public"."cards" to "service_role";

create policy "ユーザーは自分のIDでのみカードを作成可能"
on "public"."cards"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "ユーザーは自分のカードデータのみ削除可能"
on "public"."cards"
as permissive
for delete
to public
using ((auth.uid() = user_id));


create policy "ユーザーは自分のカードデータのみ参照可能"
on "public"."cards"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "ユーザーは自分のカードデータのみ更新可能"
on "public"."cards"
as permissive
for update
to public
using ((auth.uid() = user_id));


CREATE TRIGGER update_cards_updated_at BEFORE UPDATE ON public.cards FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


