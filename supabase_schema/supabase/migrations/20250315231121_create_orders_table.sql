create table "public"."orders" (
    "id" uuid not null default gen_random_uuid(),
    "order_id" character varying(32) not null,
    "user_id" uuid not null,
    "store_id" character(4) not null,
    "eat_in_takeout" smallint not null,
    "order_type" smallint not null,
    "pickup_number" character varying(32) not null,
    "price_without_tax" integer not null,
    "price_with_tax" integer not null,
    "payment_method" character varying(32) not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
);


alter table "public"."orders" enable row level security;

CREATE INDEX idx_orders_order_id ON public.orders USING btree (order_id);

CREATE INDEX idx_orders_store_id ON public.orders USING btree (store_id);

CREATE INDEX idx_orders_user_id ON public.orders USING btree (user_id);

CREATE UNIQUE INDEX orders_pkey ON public.orders USING btree (id);

alter table "public"."orders" add constraint "orders_pkey" PRIMARY KEY using index "orders_pkey";

alter table "public"."orders" add constraint "orders_eat_in_takeout_check" CHECK ((eat_in_takeout = ANY (ARRAY[1, 2]))) not valid;

alter table "public"."orders" validate constraint "orders_eat_in_takeout_check";

alter table "public"."orders" add constraint "orders_order_type_check" CHECK ((order_type = ANY (ARRAY[1, 2]))) not valid;

alter table "public"."orders" validate constraint "orders_order_type_check";

alter table "public"."orders" add constraint "orders_store_id_fkey" FOREIGN KEY (store_id) REFERENCES stores(store_number) not valid;

alter table "public"."orders" validate constraint "orders_store_id_fkey";

alter table "public"."orders" add constraint "orders_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."orders" validate constraint "orders_user_id_fkey";

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

grant delete on table "public"."orders" to "anon";

grant insert on table "public"."orders" to "anon";

grant references on table "public"."orders" to "anon";

grant select on table "public"."orders" to "anon";

grant trigger on table "public"."orders" to "anon";

grant truncate on table "public"."orders" to "anon";

grant update on table "public"."orders" to "anon";

grant delete on table "public"."orders" to "authenticated";

grant insert on table "public"."orders" to "authenticated";

grant references on table "public"."orders" to "authenticated";

grant select on table "public"."orders" to "authenticated";

grant trigger on table "public"."orders" to "authenticated";

grant truncate on table "public"."orders" to "authenticated";

grant update on table "public"."orders" to "authenticated";

grant delete on table "public"."orders" to "service_role";

grant insert on table "public"."orders" to "service_role";

grant references on table "public"."orders" to "service_role";

grant select on table "public"."orders" to "service_role";

grant trigger on table "public"."orders" to "service_role";

grant truncate on table "public"."orders" to "service_role";

grant update on table "public"."orders" to "service_role";

create policy "deny_all_orders"
on "public"."orders"
as permissive
for all
to public
using (false);


create policy "insert_own_orders"
on "public"."orders"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "select_own_orders"
on "public"."orders"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "update_own_orders"
on "public"."orders"
as permissive
for update
to public
using ((auth.uid() = user_id));


CREATE TRIGGER orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION update_timestamp();


