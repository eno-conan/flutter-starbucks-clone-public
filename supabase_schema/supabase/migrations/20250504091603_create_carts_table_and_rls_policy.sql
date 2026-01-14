create table "public"."carts" (
    "user_id" uuid not null,
    "store_number" text not null,
    "eat_in_takeout" smallint,
    "order_type" smallint,
    "price_without_tax" integer,
    "price_with_tax" integer,
    "payment_method" text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
);


alter table "public"."carts" enable row level security;

CREATE UNIQUE INDEX carts_pkey ON public.carts USING btree (user_id);

alter table "public"."carts" add constraint "carts_pkey" PRIMARY KEY using index "carts_pkey";

alter table "public"."carts" add constraint "carts_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."carts" validate constraint "carts_user_id_fkey";

grant delete on table "public"."carts" to "anon";

grant insert on table "public"."carts" to "anon";

grant references on table "public"."carts" to "anon";

grant select on table "public"."carts" to "anon";

grant trigger on table "public"."carts" to "anon";

grant truncate on table "public"."carts" to "anon";

grant update on table "public"."carts" to "anon";

grant delete on table "public"."carts" to "authenticated";

grant insert on table "public"."carts" to "authenticated";

grant references on table "public"."carts" to "authenticated";

grant select on table "public"."carts" to "authenticated";

grant trigger on table "public"."carts" to "authenticated";

grant truncate on table "public"."carts" to "authenticated";

grant update on table "public"."carts" to "authenticated";

grant delete on table "public"."carts" to "service_role";

grant insert on table "public"."carts" to "service_role";

grant references on table "public"."carts" to "service_role";

grant select on table "public"."carts" to "service_role";

grant trigger on table "public"."carts" to "service_role";

grant truncate on table "public"."carts" to "service_role";

grant update on table "public"."carts" to "service_role";

create policy "ユーザーは自分のカートのみ削除可能"
on "public"."carts"
as permissive
for delete
to authenticated
using ((auth.uid() = user_id));


create policy "ユーザーは自分のカートのみ更新可能"
on "public"."carts"
as permissive
for update
to authenticated
using ((auth.uid() = user_id));


create policy "ユーザーは自分のカートのみ閲覧可能"
on "public"."carts"
as permissive
for select
to authenticated
using ((auth.uid() = user_id));


create policy "全ユーザーがカートに追加可能"
on "public"."carts"
as permissive
for insert
to authenticated, anon
with check (true);



