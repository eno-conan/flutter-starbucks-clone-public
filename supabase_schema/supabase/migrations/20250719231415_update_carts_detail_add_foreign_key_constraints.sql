alter table "public"."carts_detail" add constraint "carts_detail_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(product_id) not valid;

alter table "public"."carts_detail" validate constraint "carts_detail_product_id_fkey";

alter table "public"."carts_detail" add constraint "carts_detail_size_id_fkey" FOREIGN KEY (size_id) REFERENCES sizes(size_id) not valid;

alter table "public"."carts_detail" validate constraint "carts_detail_size_id_fkey";

alter table "public"."carts_detail" add constraint "carts_detail_temperature_type_id_fkey" FOREIGN KEY (temperature_type_id) REFERENCES temperature_types(temperature_type_id) not valid;

alter table "public"."carts_detail" validate constraint "carts_detail_temperature_type_id_fkey";


