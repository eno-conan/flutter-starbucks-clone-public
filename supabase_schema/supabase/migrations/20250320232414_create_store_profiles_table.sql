create sequence "public"."store_profiles_id_seq";

create table "public"."store_profiles" (
    "id" integer not null default nextval('store_profiles_id_seq'::regclass),
    "store_number" character(4) not null,
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."store_profiles" enable row level security;

alter sequence "public"."store_profiles_id_seq" owned by "public"."store_profiles"."id";

CREATE UNIQUE INDEX store_profiles_pkey ON public.store_profiles USING btree (id);

CREATE UNIQUE INDEX unique_user_id ON public.store_profiles USING btree (user_id);

alter table "public"."store_profiles" add constraint "store_profiles_pkey" PRIMARY KEY using index "store_profiles_pkey";

alter table "public"."store_profiles" add constraint "store_profiles_store_number_fkey" FOREIGN KEY (store_number) REFERENCES stores(store_number) not valid;

alter table "public"."store_profiles" validate constraint "store_profiles_store_number_fkey";

alter table "public"."store_profiles" add constraint "store_profiles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."store_profiles" validate constraint "store_profiles_user_id_fkey";

alter table "public"."store_profiles" add constraint "unique_user_id" UNIQUE using index "unique_user_id";

grant delete on table "public"."store_profiles" to "anon";

grant insert on table "public"."store_profiles" to "anon";

grant references on table "public"."store_profiles" to "anon";

grant select on table "public"."store_profiles" to "anon";

grant trigger on table "public"."store_profiles" to "anon";

grant truncate on table "public"."store_profiles" to "anon";

grant update on table "public"."store_profiles" to "anon";

grant delete on table "public"."store_profiles" to "authenticated";

grant insert on table "public"."store_profiles" to "authenticated";

grant references on table "public"."store_profiles" to "authenticated";

grant select on table "public"."store_profiles" to "authenticated";

grant trigger on table "public"."store_profiles" to "authenticated";

grant truncate on table "public"."store_profiles" to "authenticated";

grant update on table "public"."store_profiles" to "authenticated";

grant delete on table "public"."store_profiles" to "service_role";

grant insert on table "public"."store_profiles" to "service_role";

grant references on table "public"."store_profiles" to "service_role";

grant select on table "public"."store_profiles" to "service_role";

grant trigger on table "public"."store_profiles" to "service_role";

grant truncate on table "public"."store_profiles" to "service_role";

grant update on table "public"."store_profiles" to "service_role";

create policy "店舗は自分の注文のみ閲覧可能"
on "public"."orders"
as permissive
for select
to public
using ((EXISTS ( SELECT 1
   FROM store_profiles
  WHERE ((store_profiles.user_id = auth.uid()) AND (store_profiles.store_number = orders.store_id)))));


create policy "店舗は自分の注文詳細のみ閲覧可能"
on "public"."orders_detail"
as permissive
for select
to public
using ((EXISTS ( SELECT 1
   FROM (orders o
     JOIN store_profiles sp ON ((o.store_id = sp.store_number)))
  WHERE ((sp.user_id = auth.uid()) AND ((o.order_id)::text = (orders_detail.order_id)::text)))));


create policy "店舗は自分の情報のみ閲覧可能"
on "public"."store_profiles"
as permissive
for select
to public
using ((auth.uid() = user_id));



