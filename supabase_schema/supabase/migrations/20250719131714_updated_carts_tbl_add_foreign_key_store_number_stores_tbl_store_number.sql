alter table "public"."carts" alter column "store_number" set data type character(4) using "store_number"::character(4);

alter table "public"."carts" add constraint "carts_store_number_fkey" FOREIGN KEY (store_number) REFERENCES stores(store_number) not valid;

alter table "public"."carts" validate constraint "carts_store_number_fkey";


