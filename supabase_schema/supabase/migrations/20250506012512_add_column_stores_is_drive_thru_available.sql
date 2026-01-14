alter table "public"."stores" add column "is_drive_thru_available" character(1) not null default '0'::bpchar;

alter table "public"."stores" add constraint "stores_is_drive_thru_available_check" CHECK ((is_drive_thru_available = ANY (ARRAY['0'::bpchar, '1'::bpchar]))) not valid;

alter table "public"."stores" validate constraint "stores_is_drive_thru_available_check";


