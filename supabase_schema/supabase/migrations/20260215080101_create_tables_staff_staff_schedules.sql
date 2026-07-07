create sequence "public"."staff_schedules_id_seq";


  create table "public"."staff" (
    "staff_number" character varying(50) not null,
    "staff_name" character varying(100) not null,
    "email" character varying(255),
    "phone" character varying(20),
    "employment_type" character varying(20),
    "hire_date" date,
    "termination_date" date,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."staff" enable row level security;


  create table "public"."staff_schedules" (
    "id" bigint not null default nextval('public.staff_schedules_id_seq'::regclass),
    "date" date not null,
    "staff_number" character varying(50) not null,
    "store_number" character varying(50),
    "period_1" boolean default false,
    "period_2" boolean default false,
    "period_3" boolean default false,
    "period_4" boolean default false,
    "period_5" boolean default false,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."staff_schedules" enable row level security;

alter sequence "public"."staff_schedules_id_seq" owned by "public"."staff_schedules"."id";

CREATE INDEX idx_staff_schedules_date_staff ON public.staff_schedules USING btree (date, staff_number);

CREATE INDEX idx_staff_schedules_staff ON public.staff_schedules USING btree (staff_number);

CREATE INDEX idx_staff_schedules_store_date ON public.staff_schedules USING btree (store_number, date);

CREATE UNIQUE INDEX staff_pkey ON public.staff USING btree (staff_number);

CREATE UNIQUE INDEX staff_schedules_pkey ON public.staff_schedules USING btree (id);

CREATE UNIQUE INDEX unique_staff_date ON public.staff_schedules USING btree (date, staff_number);

alter table "public"."staff" add constraint "staff_pkey" PRIMARY KEY using index "staff_pkey";

alter table "public"."staff_schedules" add constraint "staff_schedules_pkey" PRIMARY KEY using index "staff_schedules_pkey";

alter table "public"."staff_schedules" add constraint "fk_staff_schedules_staff" FOREIGN KEY (staff_number) REFERENCES public.staff(staff_number) not valid;

alter table "public"."staff_schedules" validate constraint "fk_staff_schedules_staff";

alter table "public"."staff_schedules" add constraint "unique_staff_date" UNIQUE using index "unique_staff_date";

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

grant delete on table "public"."staff" to "anon";

grant insert on table "public"."staff" to "anon";

grant references on table "public"."staff" to "anon";

grant select on table "public"."staff" to "anon";

grant trigger on table "public"."staff" to "anon";

grant truncate on table "public"."staff" to "anon";

grant update on table "public"."staff" to "anon";

grant delete on table "public"."staff" to "authenticated";

grant insert on table "public"."staff" to "authenticated";

grant references on table "public"."staff" to "authenticated";

grant select on table "public"."staff" to "authenticated";

grant trigger on table "public"."staff" to "authenticated";

grant truncate on table "public"."staff" to "authenticated";

grant update on table "public"."staff" to "authenticated";

grant delete on table "public"."staff" to "postgres";

grant insert on table "public"."staff" to "postgres";

grant references on table "public"."staff" to "postgres";

grant select on table "public"."staff" to "postgres";

grant trigger on table "public"."staff" to "postgres";

grant truncate on table "public"."staff" to "postgres";

grant update on table "public"."staff" to "postgres";

grant delete on table "public"."staff" to "service_role";

grant insert on table "public"."staff" to "service_role";

grant references on table "public"."staff" to "service_role";

grant select on table "public"."staff" to "service_role";

grant trigger on table "public"."staff" to "service_role";

grant truncate on table "public"."staff" to "service_role";

grant update on table "public"."staff" to "service_role";

grant delete on table "public"."staff_schedules" to "anon";

grant insert on table "public"."staff_schedules" to "anon";

grant references on table "public"."staff_schedules" to "anon";

grant select on table "public"."staff_schedules" to "anon";

grant trigger on table "public"."staff_schedules" to "anon";

grant truncate on table "public"."staff_schedules" to "anon";

grant update on table "public"."staff_schedules" to "anon";

grant delete on table "public"."staff_schedules" to "authenticated";

grant insert on table "public"."staff_schedules" to "authenticated";

grant references on table "public"."staff_schedules" to "authenticated";

grant select on table "public"."staff_schedules" to "authenticated";

grant trigger on table "public"."staff_schedules" to "authenticated";

grant truncate on table "public"."staff_schedules" to "authenticated";

grant update on table "public"."staff_schedules" to "authenticated";

grant delete on table "public"."staff_schedules" to "postgres";

grant insert on table "public"."staff_schedules" to "postgres";

grant references on table "public"."staff_schedules" to "postgres";

grant select on table "public"."staff_schedules" to "postgres";

grant trigger on table "public"."staff_schedules" to "postgres";

grant truncate on table "public"."staff_schedules" to "postgres";

grant update on table "public"."staff_schedules" to "postgres";

grant delete on table "public"."staff_schedules" to "service_role";

grant insert on table "public"."staff_schedules" to "service_role";

grant references on table "public"."staff_schedules" to "service_role";

grant select on table "public"."staff_schedules" to "service_role";

grant trigger on table "public"."staff_schedules" to "service_role";

grant truncate on table "public"."staff_schedules" to "service_role";

grant update on table "public"."staff_schedules" to "service_role";


  create policy "Enable read access for authenticated users"
  on "public"."staff"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Enable read access for authenticated users"
  on "public"."staff_schedules"
  as permissive
  for select
  to authenticated
using (true);


CREATE TRIGGER update_staff_updated_at BEFORE UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_staff_schedules_updated_at BEFORE UPDATE ON public.staff_schedules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();