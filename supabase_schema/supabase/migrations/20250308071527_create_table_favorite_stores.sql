create table "public"."favorite_stores" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "store_number" character(4) not null,
    "created_at" timestamp with time zone default CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone default CURRENT_TIMESTAMP
);


alter table "public"."favorite_stores" enable row level security;

CREATE UNIQUE INDEX favorite_stores_pkey ON public.favorite_stores USING btree (id);

alter table "public"."favorite_stores" add constraint "favorite_stores_pkey" PRIMARY KEY using index "favorite_stores_pkey";

alter table "public"."favorite_stores" add constraint "favorite_stores_store_number_fkey" FOREIGN KEY (store_number) REFERENCES stores(store_number) not valid;

alter table "public"."favorite_stores" validate constraint "favorite_stores_store_number_fkey";

alter table "public"."favorite_stores" add constraint "favorite_stores_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."favorite_stores" validate constraint "favorite_stores_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_nearby_stores(lat double precision, lng double precision, radius_km double precision)
 RETURNS TABLE(id integer, store_name character varying, address character varying, closing_time time without time zone, opening_time time without time zone, latitude double precision, longitude double precision, distance_km double precision)
 LANGUAGE sql
AS $function$WITH stores_with_distance AS (
    SELECT 
      s.id,
      s.store_name,
      s.address,
      s.closing_time,
      s.opening_time,
      s.latitude,
      s.longitude,
      6371 * acos(
        cos(radians(lat)) * cos(radians(s.latitude)) *
        cos(radians(s.longitude) - radians(lng)) +
        sin(radians(lat)) * sin(radians(s.latitude))
      ) AS distance_km
    FROM stores s
    WHERE s.closing_date IS NULL OR s.closing_date > CURRENT_DATE
  )
  SELECT 
    id,
    store_name,
    address,
    closing_time,
    opening_time,
    latitude,
    longitude,
    distance_km
  FROM stores_with_distance
  WHERE distance_km < radius_km
  ORDER BY distance_km
  LIMIT 10;$function$
;

grant delete on table "public"."favorite_stores" to "anon";

grant insert on table "public"."favorite_stores" to "anon";

grant references on table "public"."favorite_stores" to "anon";

grant select on table "public"."favorite_stores" to "anon";

grant trigger on table "public"."favorite_stores" to "anon";

grant truncate on table "public"."favorite_stores" to "anon";

grant update on table "public"."favorite_stores" to "anon";

grant delete on table "public"."favorite_stores" to "authenticated";

grant insert on table "public"."favorite_stores" to "authenticated";

grant references on table "public"."favorite_stores" to "authenticated";

grant select on table "public"."favorite_stores" to "authenticated";

grant trigger on table "public"."favorite_stores" to "authenticated";

grant truncate on table "public"."favorite_stores" to "authenticated";

grant update on table "public"."favorite_stores" to "authenticated";

grant delete on table "public"."favorite_stores" to "service_role";

grant insert on table "public"."favorite_stores" to "service_role";

grant references on table "public"."favorite_stores" to "service_role";

grant select on table "public"."favorite_stores" to "service_role";

grant trigger on table "public"."favorite_stores" to "service_role";

grant truncate on table "public"."favorite_stores" to "service_role";

grant update on table "public"."favorite_stores" to "service_role";

create policy "Users can delete their own favorite stores"
on "public"."favorite_stores"
as permissive
for delete
to public
using ((auth.uid() = user_id));


create policy "Users can insert their own favorite stores"
on "public"."favorite_stores"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "Users can update their own favorite stores"
on "public"."favorite_stores"
as permissive
for update
to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own favorite stores"
on "public"."favorite_stores"
as permissive
for select
to public
using ((auth.uid() = user_id));



