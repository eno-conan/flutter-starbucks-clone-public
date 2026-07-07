-- 未使用INDEXの削除
-- Supabase Performance Advisor: unused_index 警告対応（15件）
-- INSERT/UPDATE時のパフォーマンス劣化を防ぐため、使用されていないINDEXを削除する

DROP INDEX IF EXISTS public.idx_carts_detail_product_id;
DROP INDEX IF EXISTS public.idx_orders_detail_product_id;
DROP INDEX IF EXISTS public.idx_products_category_display_order;
DROP INDEX IF EXISTS public.idx_star_acquisitions_order_id;
DROP INDEX IF EXISTS public.idx_star_usage_exchange_item_id;
DROP INDEX IF EXISTS public.idx_product_sizes_size_id;
DROP INDEX IF EXISTS public.kv_store_aac956c6_key_idx;
DROP INDEX IF EXISTS public.idx_poc_realtime_created_at;
DROP INDEX IF EXISTS public.idx_poc_realtime_user_id;
DROP INDEX IF EXISTS public.idx_cards_card_id;
DROP INDEX IF EXISTS public.idx_purchase_history_purchase_datetime;
DROP INDEX IF EXISTS public.idx_purchase_history_user_id;
DROP INDEX IF EXISTS public.pre_signup_users_email_idx;
DROP INDEX IF EXISTS public.idx_staff_schedules_store_date;
DROP INDEX IF EXISTS public.idx_staff_schedules_date_staff;
