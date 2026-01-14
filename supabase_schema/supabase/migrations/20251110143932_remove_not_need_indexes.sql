drop index if exists "public"."idx_carts_detail_size_id";

drop index if exists "public"."idx_carts_detail_temperature_type_id";

drop index if exists "public"."idx_display_order";

drop index if exists "public"."idx_orders_detail_size_id";

drop index if exists "public"."idx_orders_detail_temperature_type_id";

drop index if exists "public"."idx_product_sizes";

drop index if exists "public"."idx_product_temperature";

drop index if exists "public"."idx_product_temperature_types_temperature_type_id";

drop index if exists "public"."idx_products_category";

CREATE INDEX idx_products_category_display_order ON public.products USING btree (category_id, display_order) WHERE (is_active = true);


