create sequence "public"."e_tickets_promotions_id_seq";

create sequence "public"."e_tickets_special_offers_id_seq";

create sequence "public"."user_tickets_id_seq";


  create table "public"."e_tickets_promotions" (
    "id" integer not null default nextval('public.e_tickets_promotions_id_seq'::regclass),
    "short_name" text not null,
    "name" text not null,
    "image_url" text,
    "discount_type" text not null,
    "discount_value" integer not null,
    "is_birthday_month_only" boolean not null default false,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."e_tickets_promotions" enable row level security;


  create table "public"."e_tickets_special_offers" (
    "id" integer not null default nextval('public.e_tickets_special_offers_id_seq'::regclass),
    "short_name" text not null,
    "name" text not null,
    "image_url" text,
    "special_price" integer not null,
    "target_sku_id" text not null,
    "max_quantity_per_order" integer not null default 1,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."e_tickets_special_offers" enable row level security;


  create table "public"."user_tickets" (
    "id" integer not null default nextval('public.user_tickets_id_seq'::regclass),
    "user_id" uuid not null,
    "ticket_type" text not null,
    "definition_id" integer not null,
    "expired_at" timestamp with time zone not null,
    "is_used" boolean not null default false,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."user_tickets" enable row level security;

alter sequence "public"."e_tickets_promotions_id_seq" owned by "public"."e_tickets_promotions"."id";

alter sequence "public"."e_tickets_special_offers_id_seq" owned by "public"."e_tickets_special_offers"."id";

alter sequence "public"."user_tickets_id_seq" owned by "public"."user_tickets"."id";

CREATE UNIQUE INDEX e_tickets_promotions_pkey ON public.e_tickets_promotions USING btree (id);

CREATE UNIQUE INDEX e_tickets_special_offers_pkey ON public.e_tickets_special_offers USING btree (id);

CREATE UNIQUE INDEX user_tickets_pkey ON public.user_tickets USING btree (id);

alter table "public"."e_tickets_promotions" add constraint "e_tickets_promotions_pkey" PRIMARY KEY using index "e_tickets_promotions_pkey";

alter table "public"."e_tickets_special_offers" add constraint "e_tickets_special_offers_pkey" PRIMARY KEY using index "e_tickets_special_offers_pkey";

alter table "public"."user_tickets" add constraint "user_tickets_pkey" PRIMARY KEY using index "user_tickets_pkey";

alter table "public"."user_tickets" add constraint "user_tickets_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."user_tickets" validate constraint "user_tickets_user_id_fkey";

grant delete on table "public"."e_tickets_promotions" to "anon";

grant insert on table "public"."e_tickets_promotions" to "anon";

grant references on table "public"."e_tickets_promotions" to "anon";

grant select on table "public"."e_tickets_promotions" to "anon";

grant trigger on table "public"."e_tickets_promotions" to "anon";

grant truncate on table "public"."e_tickets_promotions" to "anon";

grant update on table "public"."e_tickets_promotions" to "anon";

grant delete on table "public"."e_tickets_promotions" to "authenticated";

grant insert on table "public"."e_tickets_promotions" to "authenticated";

grant references on table "public"."e_tickets_promotions" to "authenticated";

grant select on table "public"."e_tickets_promotions" to "authenticated";

grant trigger on table "public"."e_tickets_promotions" to "authenticated";

grant truncate on table "public"."e_tickets_promotions" to "authenticated";

grant update on table "public"."e_tickets_promotions" to "authenticated";

grant delete on table "public"."e_tickets_promotions" to "service_role";

grant insert on table "public"."e_tickets_promotions" to "service_role";

grant references on table "public"."e_tickets_promotions" to "service_role";

grant select on table "public"."e_tickets_promotions" to "service_role";

grant trigger on table "public"."e_tickets_promotions" to "service_role";

grant truncate on table "public"."e_tickets_promotions" to "service_role";

grant update on table "public"."e_tickets_promotions" to "service_role";

grant delete on table "public"."e_tickets_special_offers" to "anon";

grant insert on table "public"."e_tickets_special_offers" to "anon";

grant references on table "public"."e_tickets_special_offers" to "anon";

grant select on table "public"."e_tickets_special_offers" to "anon";

grant trigger on table "public"."e_tickets_special_offers" to "anon";

grant truncate on table "public"."e_tickets_special_offers" to "anon";

grant update on table "public"."e_tickets_special_offers" to "anon";

grant delete on table "public"."e_tickets_special_offers" to "authenticated";

grant insert on table "public"."e_tickets_special_offers" to "authenticated";

grant references on table "public"."e_tickets_special_offers" to "authenticated";

grant select on table "public"."e_tickets_special_offers" to "authenticated";

grant trigger on table "public"."e_tickets_special_offers" to "authenticated";

grant truncate on table "public"."e_tickets_special_offers" to "authenticated";

grant update on table "public"."e_tickets_special_offers" to "authenticated";

grant delete on table "public"."e_tickets_special_offers" to "service_role";

grant insert on table "public"."e_tickets_special_offers" to "service_role";

grant references on table "public"."e_tickets_special_offers" to "service_role";

grant select on table "public"."e_tickets_special_offers" to "service_role";

grant trigger on table "public"."e_tickets_special_offers" to "service_role";

grant truncate on table "public"."e_tickets_special_offers" to "service_role";

grant update on table "public"."e_tickets_special_offers" to "service_role";

grant delete on table "public"."user_tickets" to "anon";

grant insert on table "public"."user_tickets" to "anon";

grant references on table "public"."user_tickets" to "anon";

grant select on table "public"."user_tickets" to "anon";

grant trigger on table "public"."user_tickets" to "anon";

grant truncate on table "public"."user_tickets" to "anon";

grant update on table "public"."user_tickets" to "anon";

grant delete on table "public"."user_tickets" to "authenticated";

grant insert on table "public"."user_tickets" to "authenticated";

grant references on table "public"."user_tickets" to "authenticated";

grant select on table "public"."user_tickets" to "authenticated";

grant trigger on table "public"."user_tickets" to "authenticated";

grant truncate on table "public"."user_tickets" to "authenticated";

grant update on table "public"."user_tickets" to "authenticated";

grant delete on table "public"."user_tickets" to "service_role";

grant insert on table "public"."user_tickets" to "service_role";

grant references on table "public"."user_tickets" to "service_role";

grant select on table "public"."user_tickets" to "service_role";

grant trigger on table "public"."user_tickets" to "service_role";

grant truncate on table "public"."user_tickets" to "service_role";

grant update on table "public"."user_tickets" to "service_role";


  create policy "delete_own_eticket"
  on "public"."user_tickets"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "insert_own_eticket"
  on "public"."user_tickets"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "select_own_etickets"
  on "public"."user_tickets"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "update_own_eticket"
  on "public"."user_tickets"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



