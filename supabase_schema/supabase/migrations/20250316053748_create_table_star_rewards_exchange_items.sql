create sequence "public"."star_rewards_exchange_items_id_seq";

create table "public"."star_rewards_exchange_items" (
    "id" integer not null default nextval('star_rewards_exchange_items_id_seq'::regclass),
    "short_name" text not null,
    "name" text not null,
    "image_url" text,
    "points" integer not null
);


alter table "public"."star_rewards_exchange_items" enable row level security;

alter sequence "public"."star_rewards_exchange_items_id_seq" owned by "public"."star_rewards_exchange_items"."id";

CREATE UNIQUE INDEX star_rewards_exchange_items_pkey ON public.star_rewards_exchange_items USING btree (id);

alter table "public"."star_rewards_exchange_items" add constraint "star_rewards_exchange_items_pkey" PRIMARY KEY using index "star_rewards_exchange_items_pkey";

grant delete on table "public"."star_rewards_exchange_items" to "anon";

grant insert on table "public"."star_rewards_exchange_items" to "anon";

grant references on table "public"."star_rewards_exchange_items" to "anon";

grant select on table "public"."star_rewards_exchange_items" to "anon";

grant trigger on table "public"."star_rewards_exchange_items" to "anon";

grant truncate on table "public"."star_rewards_exchange_items" to "anon";

grant update on table "public"."star_rewards_exchange_items" to "anon";

grant delete on table "public"."star_rewards_exchange_items" to "authenticated";

grant insert on table "public"."star_rewards_exchange_items" to "authenticated";

grant references on table "public"."star_rewards_exchange_items" to "authenticated";

grant select on table "public"."star_rewards_exchange_items" to "authenticated";

grant trigger on table "public"."star_rewards_exchange_items" to "authenticated";

grant truncate on table "public"."star_rewards_exchange_items" to "authenticated";

grant update on table "public"."star_rewards_exchange_items" to "authenticated";

grant delete on table "public"."star_rewards_exchange_items" to "service_role";

grant insert on table "public"."star_rewards_exchange_items" to "service_role";

grant references on table "public"."star_rewards_exchange_items" to "service_role";

grant select on table "public"."star_rewards_exchange_items" to "service_role";

grant trigger on table "public"."star_rewards_exchange_items" to "service_role";

grant truncate on table "public"."star_rewards_exchange_items" to "service_role";

grant update on table "public"."star_rewards_exchange_items" to "service_role";

create policy "star_rewards_exchange_items_select_policy"
on "public"."star_rewards_exchange_items"
as permissive
for select
to public
using (true);



