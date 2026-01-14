alter table "public"."carts" alter column "usage" set default 1;

alter table "public"."carts" alter column "usage" set not null;

alter table "public"."carts" add constraint "carts_usage_check" CHECK ((usage = ANY (ARRAY[1, 2, 3]))) not valid;

alter table "public"."carts" validate constraint "carts_usage_check";

