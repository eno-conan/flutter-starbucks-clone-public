
  create table "public"."poc_realtime" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."poc_realtime" enable row level security;

CREATE INDEX idx_poc_realtime_created_at ON public.poc_realtime USING btree (created_at DESC);

CREATE INDEX idx_poc_realtime_user_id ON public.poc_realtime USING btree (user_id);

CREATE UNIQUE INDEX poc_realtime_pkey ON public.poc_realtime USING btree (id);

alter table "public"."poc_realtime" add constraint "poc_realtime_pkey" PRIMARY KEY using index "poc_realtime_pkey";

alter table "public"."poc_realtime" add constraint "poc_realtime_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."poc_realtime" validate constraint "poc_realtime_user_id_fkey";

grant delete on table "public"."poc_realtime" to "anon";

grant insert on table "public"."poc_realtime" to "anon";

grant references on table "public"."poc_realtime" to "anon";

grant select on table "public"."poc_realtime" to "anon";

grant trigger on table "public"."poc_realtime" to "anon";

grant truncate on table "public"."poc_realtime" to "anon";

grant update on table "public"."poc_realtime" to "anon";

grant delete on table "public"."poc_realtime" to "authenticated";

grant insert on table "public"."poc_realtime" to "authenticated";

grant references on table "public"."poc_realtime" to "authenticated";

grant select on table "public"."poc_realtime" to "authenticated";

grant trigger on table "public"."poc_realtime" to "authenticated";

grant truncate on table "public"."poc_realtime" to "authenticated";

grant update on table "public"."poc_realtime" to "authenticated";

grant delete on table "public"."poc_realtime" to "postgres";

grant insert on table "public"."poc_realtime" to "postgres";

grant references on table "public"."poc_realtime" to "postgres";

grant select on table "public"."poc_realtime" to "postgres";

grant trigger on table "public"."poc_realtime" to "postgres";

grant truncate on table "public"."poc_realtime" to "postgres";

grant update on table "public"."poc_realtime" to "postgres";

grant delete on table "public"."poc_realtime" to "service_role";

grant insert on table "public"."poc_realtime" to "service_role";

grant references on table "public"."poc_realtime" to "service_role";

grant select on table "public"."poc_realtime" to "service_role";

grant trigger on table "public"."poc_realtime" to "service_role";

grant truncate on table "public"."poc_realtime" to "service_role";

grant update on table "public"."poc_realtime" to "service_role";


  create policy "Anyone can view poc_realtime records"
  on "public"."poc_realtime"
  as permissive
  for select
  to public
using (true);



  create policy "Authenticated users can insert poc_realtime records"
  on "public"."poc_realtime"
  as permissive
  for insert
  to public
with check ((auth.role() = 'authenticated'::text));

