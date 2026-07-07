-- 外部キーへのINDEX追加
-- Supabase Performance Advisor: unindexed_foreign_keys 警告対応（12件）
-- 外部キー制約にカバーリングINDEXを追加してクエリパフォーマンスを改善する

CREATE INDEX IF NOT EXISTS idx_carts_store_number
    ON public.carts USING btree (store_number);

CREATE INDEX IF NOT EXISTS idx_carts_detail_size_id
    ON public.carts_detail USING btree (size_id);

CREATE INDEX IF NOT EXISTS idx_carts_detail_temperature_type_id
    ON public.carts_detail USING btree (temperature_type_id);

CREATE INDEX IF NOT EXISTS idx_orders_detail_size_id
    ON public.orders_detail USING btree (size_id);

CREATE INDEX IF NOT EXISTS idx_orders_detail_temperature_type_id
    ON public.orders_detail USING btree (temperature_type_id);

CREATE INDEX IF NOT EXISTS idx_product_temperature_types_temperature_type_id
    ON public.product_temperature_types USING btree (temperature_type_id);

CREATE INDEX IF NOT EXISTS idx_star_acquisitions_user_id
    ON public.star_acquisitions USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_star_usage_user_id
    ON public.star_usage USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_store_profiles_store_number
    ON public.store_profiles USING btree (store_number);

CREATE INDEX IF NOT EXISTS idx_stores_prefecture_id
    ON public.stores USING btree (prefecture_id);

CREATE INDEX IF NOT EXISTS idx_user_profile_details_prefecture_id
    ON public.user_profile_details USING btree (prefecture_id);

CREATE INDEX IF NOT EXISTS idx_user_tickets_user_id
    ON public.user_tickets USING btree (user_id);
