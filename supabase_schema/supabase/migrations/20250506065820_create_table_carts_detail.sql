create table "public"."carts_detail" (
    "user_id" uuid not null,
    "item_index" integer not null,
    "product_id" integer not null,
    "temperature_type_id" integer not null,
    "size_id" integer not null,
    "count" integer not null,
    "subtotal_without_tax" integer not null
);


alter table "public"."carts_detail" enable row level security;

CREATE UNIQUE INDEX carts_detail_pkey ON public.carts_detail USING btree (user_id, item_index);

alter table "public"."carts_detail" add constraint "carts_detail_pkey" PRIMARY KEY using index "carts_detail_pkey";

alter table "public"."carts_detail" add constraint "carts_detail_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."carts_detail" validate constraint "carts_detail_user_id_fkey";

grant delete on table "public"."carts_detail" to "anon";

grant insert on table "public"."carts_detail" to "anon";

grant references on table "public"."carts_detail" to "anon";

grant select on table "public"."carts_detail" to "anon";

grant trigger on table "public"."carts_detail" to "anon";

grant truncate on table "public"."carts_detail" to "anon";

grant update on table "public"."carts_detail" to "anon";

grant delete on table "public"."carts_detail" to "authenticated";

grant insert on table "public"."carts_detail" to "authenticated";

grant references on table "public"."carts_detail" to "authenticated";

grant select on table "public"."carts_detail" to "authenticated";

grant trigger on table "public"."carts_detail" to "authenticated";

grant truncate on table "public"."carts_detail" to "authenticated";

grant update on table "public"."carts_detail" to "authenticated";

grant delete on table "public"."carts_detail" to "service_role";

grant insert on table "public"."carts_detail" to "service_role";

grant references on table "public"."carts_detail" to "service_role";

grant select on table "public"."carts_detail" to "service_role";

grant trigger on table "public"."carts_detail" to "service_role";

grant truncate on table "public"."carts_detail" to "service_role";

grant update on table "public"."carts_detail" to "service_role";

create policy "Delete policy for carts_detail"
on "public"."carts_detail"
as permissive
for delete
to authenticated
using ((auth.uid() = user_id));


create policy "Insert policy for carts_detail"
on "public"."carts_detail"
as permissive
for insert
to authenticated
with check (true);


create policy "Select policy for carts_detail"
on "public"."carts_detail"
as permissive
for select
to authenticated
using ((auth.uid() = user_id));


create policy "Update policy for carts_detail"
on "public"."carts_detail"
as permissive
for update
to authenticated
using ((auth.uid() = user_id));



