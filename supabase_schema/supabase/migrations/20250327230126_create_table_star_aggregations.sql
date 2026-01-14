create table "public"."star_aggregations" (
    "user_id" uuid not null,
    "target_year_month" character(6) not null,
    "total_points" numeric(10,1) not null default 0,
    "expiration_datetime" timestamp with time zone not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
);


alter table "public"."star_aggregations" enable row level security;

CREATE UNIQUE INDEX star_aggregations_pkey ON public.star_aggregations USING btree (user_id, target_year_month);

alter table "public"."star_aggregations" add constraint "star_aggregations_pkey" PRIMARY KEY using index "star_aggregations_pkey";

alter table "public"."star_aggregations" add constraint "star_aggregations_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."star_aggregations" validate constraint "star_aggregations_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.set_star_aggregation_expiration()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    expiration_date DATE;
BEGIN
    -- 対象年月から13カ月後の1日を計算
    expiration_date := (
        to_date(NEW.target_year_month || '01', 'YYYYMMDD') 
        + INTERVAL '13 months'
    );
    
    NEW.expiration_datetime := expiration_date AT TIME ZONE 'UTC';
    
    RETURN NEW;
END;
$function$
;

grant delete on table "public"."star_aggregations" to "anon";

grant insert on table "public"."star_aggregations" to "anon";

grant references on table "public"."star_aggregations" to "anon";

grant select on table "public"."star_aggregations" to "anon";

grant trigger on table "public"."star_aggregations" to "anon";

grant truncate on table "public"."star_aggregations" to "anon";

grant update on table "public"."star_aggregations" to "anon";

grant delete on table "public"."star_aggregations" to "authenticated";

grant insert on table "public"."star_aggregations" to "authenticated";

grant references on table "public"."star_aggregations" to "authenticated";

grant select on table "public"."star_aggregations" to "authenticated";

grant trigger on table "public"."star_aggregations" to "authenticated";

grant truncate on table "public"."star_aggregations" to "authenticated";

grant update on table "public"."star_aggregations" to "authenticated";

grant delete on table "public"."star_aggregations" to "service_role";

grant insert on table "public"."star_aggregations" to "service_role";

grant references on table "public"."star_aggregations" to "service_role";

grant select on table "public"."star_aggregations" to "service_role";

grant trigger on table "public"."star_aggregations" to "service_role";

grant truncate on table "public"."star_aggregations" to "service_role";

grant update on table "public"."star_aggregations" to "service_role";

create policy "Users can view only their own star aggregations"
on "public"."star_aggregations"
as permissive
for all
to public
using ((auth.uid() = user_id));


CREATE TRIGGER set_expiration_trigger BEFORE INSERT OR UPDATE ON public.star_aggregations FOR EACH ROW EXECUTE FUNCTION set_star_aggregation_expiration();


