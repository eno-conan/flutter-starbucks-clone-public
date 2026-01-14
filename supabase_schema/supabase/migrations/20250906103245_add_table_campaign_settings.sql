create sequence "public"."campaign_settings_id_seq";

create table "public"."campaign_settings" (
    "id" integer not null default nextval('campaign_settings_id_seq'::regclass),
    "campaign_name" character varying(100) not null,
    "display_name" character varying(200),
    "start_date" timestamp with time zone not null,
    "end_date" timestamp with time zone not null,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."campaign_settings" enable row level security;

alter sequence "public"."campaign_settings_id_seq" owned by "public"."campaign_settings"."id";

CREATE UNIQUE INDEX campaign_settings_campaign_name_key ON public.campaign_settings USING btree (campaign_name);

CREATE UNIQUE INDEX campaign_settings_pkey ON public.campaign_settings USING btree (id);

alter table "public"."campaign_settings" add constraint "campaign_settings_pkey" PRIMARY KEY using index "campaign_settings_pkey";

alter table "public"."campaign_settings" add constraint "campaign_settings_campaign_name_key" UNIQUE using index "campaign_settings_campaign_name_key";

grant delete on table "public"."campaign_settings" to "anon";

grant insert on table "public"."campaign_settings" to "anon";

grant references on table "public"."campaign_settings" to "anon";

grant select on table "public"."campaign_settings" to "anon";

grant trigger on table "public"."campaign_settings" to "anon";

grant truncate on table "public"."campaign_settings" to "anon";

grant update on table "public"."campaign_settings" to "anon";

grant delete on table "public"."campaign_settings" to "authenticated";

grant insert on table "public"."campaign_settings" to "authenticated";

grant references on table "public"."campaign_settings" to "authenticated";

grant select on table "public"."campaign_settings" to "authenticated";

grant trigger on table "public"."campaign_settings" to "authenticated";

grant truncate on table "public"."campaign_settings" to "authenticated";

grant update on table "public"."campaign_settings" to "authenticated";

grant delete on table "public"."campaign_settings" to "service_role";

grant insert on table "public"."campaign_settings" to "service_role";

grant references on table "public"."campaign_settings" to "service_role";

grant select on table "public"."campaign_settings" to "service_role";

grant trigger on table "public"."campaign_settings" to "service_role";

grant truncate on table "public"."campaign_settings" to "service_role";

grant update on table "public"."campaign_settings" to "service_role";

create policy "authenticated_users_can_read_campaigns"
on "public"."campaign_settings"
as permissive
for select
to authenticated
using (true);



