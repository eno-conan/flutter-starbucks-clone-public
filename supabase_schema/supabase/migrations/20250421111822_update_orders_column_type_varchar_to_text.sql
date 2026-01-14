alter table "public"."orders" drop constraint "orders_provided_status_check";

alter table "public"."categories" alter column "category_name" set data type text using "category_name"::text;

alter table "public"."orders" alter column "payment_method" set data type text using "payment_method"::text;

alter table "public"."orders" alter column "pickup_number" set data type text using "pickup_number"::text;

alter table "public"."orders" alter column "provided_status" set default '0'::text;

alter table "public"."orders" alter column "provided_status" set data type text using "provided_status"::text;

alter table "public"."orders" add constraint "orders_provided_status_check" CHECK ((provided_status = ANY (ARRAY['0'::text, '1'::text, '2'::text, '99'::text]))) not valid;

alter table "public"."orders" validate constraint "orders_provided_status_check";


