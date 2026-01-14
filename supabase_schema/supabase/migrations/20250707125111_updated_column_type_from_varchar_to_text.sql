alter table "public"."prefectures" alter column "name" set data type text using "name"::text;

alter table "public"."products" alter column "product_name" set data type text using "product_name"::text;

alter table "public"."sizes" alter column "size_description" set data type text using "size_description"::text;

alter table "public"."sizes" alter column "size_name" set data type text using "size_name"::text;

alter table "public"."stores" alter column "address" set data type text using "address"::text;

alter table "public"."stores" alter column "store_name" set data type text using "store_name"::text;

alter table "public"."temperature_types" alter column "type_name" set data type text using "type_name"::text;


