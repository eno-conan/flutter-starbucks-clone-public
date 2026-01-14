CREATE INDEX idx_carts_detail_product_id ON public.carts_detail USING btree (product_id);

CREATE INDEX idx_carts_detail_size_id ON public.carts_detail USING btree (size_id);

CREATE INDEX idx_carts_detail_temperature_type_id ON public.carts_detail USING btree (temperature_type_id);

CREATE INDEX idx_orders_detail_order_id ON public.orders_detail USING btree (order_id);

CREATE INDEX idx_orders_detail_product_id ON public.orders_detail USING btree (product_id);

CREATE INDEX idx_orders_detail_size_id ON public.orders_detail USING btree (size_id);

CREATE INDEX idx_orders_detail_temperature_type_id ON public.orders_detail USING btree (temperature_type_id);

CREATE INDEX idx_orders_detail_user_id ON public.orders_detail USING btree (user_id);


