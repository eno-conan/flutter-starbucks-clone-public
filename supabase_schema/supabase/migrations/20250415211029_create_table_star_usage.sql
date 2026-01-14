create table "public"."star_usage" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "order_id" text,
    "exchange_item_id" integer,
    "point_used" numeric(10,1) not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
);


alter table "public"."star_usage" enable row level security;

CREATE UNIQUE INDEX star_usage_pkey ON public.star_usage USING btree (id);

alter table "public"."star_usage" add constraint "star_usage_pkey" PRIMARY KEY using index "star_usage_pkey";

alter table "public"."star_usage" add constraint "star_usage_exchange_item_id_fkey" FOREIGN KEY (exchange_item_id) REFERENCES star_rewards_exchange_items(id) not valid;

alter table "public"."star_usage" validate constraint "star_usage_exchange_item_id_fkey";

alter table "public"."star_usage" add constraint "star_usage_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."star_usage" validate constraint "star_usage_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$
;

grant delete on table "public"."star_usage" to "anon";

grant insert on table "public"."star_usage" to "anon";

grant references on table "public"."star_usage" to "anon";

grant select on table "public"."star_usage" to "anon";

grant trigger on table "public"."star_usage" to "anon";

grant truncate on table "public"."star_usage" to "anon";

grant update on table "public"."star_usage" to "anon";

grant delete on table "public"."star_usage" to "authenticated";

grant insert on table "public"."star_usage" to "authenticated";

grant references on table "public"."star_usage" to "authenticated";

grant select on table "public"."star_usage" to "authenticated";

grant trigger on table "public"."star_usage" to "authenticated";

grant truncate on table "public"."star_usage" to "authenticated";

grant update on table "public"."star_usage" to "authenticated";

grant delete on table "public"."star_usage" to "service_role";

grant insert on table "public"."star_usage" to "service_role";

grant references on table "public"."star_usage" to "service_role";

grant select on table "public"."star_usage" to "service_role";

grant trigger on table "public"."star_usage" to "service_role";

grant truncate on table "public"."star_usage" to "service_role";

grant update on table "public"."star_usage" to "service_role";

create policy "Users can view only their own star usage data"
on "public"."star_usage"
as permissive
for select
to public
using ((auth.uid() = user_id));


CREATE TRIGGER update_star_usage_updated_at BEFORE UPDATE ON public.star_usage FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


