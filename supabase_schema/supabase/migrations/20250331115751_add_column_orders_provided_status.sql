alter table "public"."orders" add column "provided_status" smallint not null default 0;

alter table "public"."orders" add constraint "orders_provided_status_check" CHECK ((provided_status = ANY (ARRAY[0, 1, 99]))) not valid;

alter table "public"."orders" validate constraint "orders_provided_status_check";


