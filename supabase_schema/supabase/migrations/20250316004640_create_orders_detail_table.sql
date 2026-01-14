create table "public"."orders_detail" (
    "id" uuid not null default uuid_generate_v4(),
    "order_id" character varying(32),
    "user_id" uuid,
    "product_id" integer,
    "temperature_type_id" integer,
    "size_id" integer,
    "count" integer not null,
    "subtotal_without_tax" integer not null
);


alter table "public"."orders_detail" enable row level security;

CREATE UNIQUE INDEX orders_detail_pkey ON public.orders_detail USING btree (id);

CREATE UNIQUE INDEX orders_order_id_key ON public.orders USING btree (order_id);

alter table "public"."orders_detail" add constraint "orders_detail_pkey" PRIMARY KEY using index "orders_detail_pkey";

alter table "public"."orders" add constraint "orders_order_id_key" UNIQUE using index "orders_order_id_key";

alter table "public"."orders_detail" add constraint "orders_detail_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(order_id) not valid;

alter table "public"."orders_detail" validate constraint "orders_detail_order_id_fkey";

alter table "public"."orders_detail" add constraint "orders_detail_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(product_id) not valid;

alter table "public"."orders_detail" validate constraint "orders_detail_product_id_fkey";

alter table "public"."orders_detail" add constraint "orders_detail_size_id_fkey" FOREIGN KEY (size_id) REFERENCES sizes(size_id) not valid;

alter table "public"."orders_detail" validate constraint "orders_detail_size_id_fkey";

alter table "public"."orders_detail" add constraint "orders_detail_temperature_type_id_fkey" FOREIGN KEY (temperature_type_id) REFERENCES temperature_types(temperature_type_id) not valid;

alter table "public"."orders_detail" validate constraint "orders_detail_temperature_type_id_fkey";

alter table "public"."orders_detail" add constraint "orders_detail_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."orders_detail" validate constraint "orders_detail_user_id_fkey";

grant delete on table "public"."orders_detail" to "anon";

grant insert on table "public"."orders_detail" to "anon";

grant references on table "public"."orders_detail" to "anon";

grant select on table "public"."orders_detail" to "anon";

grant trigger on table "public"."orders_detail" to "anon";

grant truncate on table "public"."orders_detail" to "anon";

grant update on table "public"."orders_detail" to "anon";

grant delete on table "public"."orders_detail" to "authenticated";

grant insert on table "public"."orders_detail" to "authenticated";

grant references on table "public"."orders_detail" to "authenticated";

grant select on table "public"."orders_detail" to "authenticated";

grant trigger on table "public"."orders_detail" to "authenticated";

grant truncate on table "public"."orders_detail" to "authenticated";

grant update on table "public"."orders_detail" to "authenticated";

grant delete on table "public"."orders_detail" to "service_role";

grant insert on table "public"."orders_detail" to "service_role";

grant references on table "public"."orders_detail" to "service_role";

grant select on table "public"."orders_detail" to "service_role";

grant trigger on table "public"."orders_detail" to "service_role";

grant truncate on table "public"."orders_detail" to "service_role";

grant update on table "public"."orders_detail" to "service_role";

create policy "Allow select for authenticated users only"
on "public"."orders_detail"
as permissive
for select
to public
using ((auth.uid() = user_id));



