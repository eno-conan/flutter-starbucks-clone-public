CREATE INDEX idx_product_sizes_size_id ON public.product_sizes USING btree (size_id);

CREATE INDEX idx_product_temperature_types_temperature_type_id ON public.product_temperature_types USING btree (temperature_type_id);

CREATE INDEX idx_star_acquisitions_order_id ON public.star_acquisitions USING btree (order_id);

CREATE INDEX idx_star_usage_exchange_item_id ON public.star_usage USING btree (exchange_item_id);


