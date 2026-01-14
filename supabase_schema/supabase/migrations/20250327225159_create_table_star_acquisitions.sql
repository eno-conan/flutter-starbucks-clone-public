create table "public"."star_acquisitions" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "order_id" character varying(32) not null,
    "category" smallint not null,
    "acquired_points" numeric(10,1) not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
);


alter table "public"."star_acquisitions" enable row level security;

CREATE UNIQUE INDEX star_acquisitions_pkey ON public.star_acquisitions USING btree (id);

alter table "public"."star_acquisitions" add constraint "star_acquisitions_pkey" PRIMARY KEY using index "star_acquisitions_pkey";

alter table "public"."star_acquisitions" add constraint "star_acquisitions_category_check" CHECK ((category = ANY (ARRAY[1, 2, 3]))) not valid;

alter table "public"."star_acquisitions" validate constraint "star_acquisitions_category_check";

alter table "public"."star_acquisitions" add constraint "star_acquisitions_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(order_id) not valid;

alter table "public"."star_acquisitions" validate constraint "star_acquisitions_order_id_fkey";

alter table "public"."star_acquisitions" add constraint "star_acquisitions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."star_acquisitions" validate constraint "star_acquisitions_user_id_fkey";

grant delete on table "public"."star_acquisitions" to "anon";

grant insert on table "public"."star_acquisitions" to "anon";

grant references on table "public"."star_acquisitions" to "anon";

grant select on table "public"."star_acquisitions" to "anon";

grant trigger on table "public"."star_acquisitions" to "anon";

grant truncate on table "public"."star_acquisitions" to "anon";

grant update on table "public"."star_acquisitions" to "anon";

grant delete on table "public"."star_acquisitions" to "authenticated";

grant insert on table "public"."star_acquisitions" to "authenticated";

grant references on table "public"."star_acquisitions" to "authenticated";

grant select on table "public"."star_acquisitions" to "authenticated";

grant trigger on table "public"."star_acquisitions" to "authenticated";

grant truncate on table "public"."star_acquisitions" to "authenticated";

grant update on table "public"."star_acquisitions" to "authenticated";

grant delete on table "public"."star_acquisitions" to "service_role";

grant insert on table "public"."star_acquisitions" to "service_role";

grant references on table "public"."star_acquisitions" to "service_role";

grant select on table "public"."star_acquisitions" to "service_role";

grant trigger on table "public"."star_acquisitions" to "service_role";

grant truncate on table "public"."star_acquisitions" to "service_role";

grant update on table "public"."star_acquisitions" to "service_role";

create policy "Users can view only their own star acquisitions"
on "public"."star_acquisitions"
as permissive
for all
to public
using ((auth.uid() = user_id));



