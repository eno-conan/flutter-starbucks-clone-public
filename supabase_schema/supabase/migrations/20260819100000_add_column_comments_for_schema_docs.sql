-- 全カラムに COMMENT ON COLUMN を付与し、テーブル定義書の「論理名」の正となる場所をDBへ移す
--
-- 背景:
--   supabase_table_definitions.md の「論理名」列は手書きで維持されており、
--   マイグレーション追加時に更新が漏れて実スキーマと乖離していた。
--   実際、この移行時点で以下の乖離が見つかっている。
--     - carts.price_without_tax / price_with_tax : 20250720065510 で削除済みなのに定義書に残存
--     - products.sale_type / display_order       : 20250812133032 で追加されたのに未記載
--     - user_tickets.used_at                     : 未記載
--
--   論理名をDBのコメントとして保持することで、
--   scripts/generate-schema-docs.js が定義書とER図を機械的に再生成できるようになる。
--
--   以降、カラムを追加・変更するマイグレーションでは COMMENT ON COLUMN を併せて記述すること。
--   記述漏れは CI (.github/workflows/schema-docs.yml) が検出する。
--
-- 対象外:
--   - spatial_ref_sys : PostGIS 拡張が所有するテーブル

-- ----------------------------------------------------------------
-- campaign_settings
-- ----------------------------------------------------------------
COMMENT ON TABLE public.campaign_settings IS 'キャンペーンの期間・表示設定';
COMMENT ON COLUMN public.campaign_settings.id IS 'ID';
COMMENT ON COLUMN public.campaign_settings.campaign_name IS 'キャンペーン名';
COMMENT ON COLUMN public.campaign_settings.display_name IS '表示名';
COMMENT ON COLUMN public.campaign_settings.start_date IS '開始日時';
COMMENT ON COLUMN public.campaign_settings.end_date IS '終了日時';
COMMENT ON COLUMN public.campaign_settings.is_active IS '有効フラグ';
COMMENT ON COLUMN public.campaign_settings.created_at IS '作成日時';
COMMENT ON COLUMN public.campaign_settings.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- cards
-- ----------------------------------------------------------------
COMMENT ON TABLE public.cards IS 'ユーザーが保有するプリペイドカード';
COMMENT ON COLUMN public.cards.id IS 'ID';
COMMENT ON COLUMN public.cards.card_id IS 'カードID';
COMMENT ON COLUMN public.cards.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.cards.card_name IS 'カード名';
COMMENT ON COLUMN public.cards.image_url IS '画像URL';
COMMENT ON COLUMN public.cards.balance IS '残高';
COMMENT ON COLUMN public.cards.is_main IS 'メインカードフラグ';
COMMENT ON COLUMN public.cards.created_at IS '作成日時';
COMMENT ON COLUMN public.cards.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- carts
-- ----------------------------------------------------------------
COMMENT ON TABLE public.carts IS 'ユーザーごとのカート（1ユーザー1カート）';
COMMENT ON COLUMN public.carts.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.carts.store_number IS '店舗番号';
COMMENT ON COLUMN public.carts.payment_method IS '支払方法';
COMMENT ON COLUMN public.carts.created_at IS '作成日時';
COMMENT ON COLUMN public.carts.updated_at IS '更新日時';
COMMENT ON COLUMN public.carts.usage IS '利用区分';

-- ----------------------------------------------------------------
-- carts_detail
-- ----------------------------------------------------------------
COMMENT ON TABLE public.carts_detail IS 'カート明細';
COMMENT ON COLUMN public.carts_detail.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.carts_detail.item_index IS '商品インデックス';
COMMENT ON COLUMN public.carts_detail.product_id IS '商品ID';
COMMENT ON COLUMN public.carts_detail.temperature_type_id IS '温度タイプID';
COMMENT ON COLUMN public.carts_detail.size_id IS 'サイズID';
COMMENT ON COLUMN public.carts_detail.count IS '数量';
COMMENT ON COLUMN public.carts_detail.subtotal_without_tax IS '税抜小計';

-- ----------------------------------------------------------------
-- categories
-- ----------------------------------------------------------------
COMMENT ON TABLE public.categories IS '商品カテゴリマスタ';
COMMENT ON COLUMN public.categories.category_id IS 'カテゴリID';
COMMENT ON COLUMN public.categories.category_name IS 'カテゴリ名';
COMMENT ON COLUMN public.categories.description IS '説明';
COMMENT ON COLUMN public.categories.created_at IS '作成日時';
COMMENT ON COLUMN public.categories.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- e_tickets_promotions
-- ----------------------------------------------------------------
COMMENT ON TABLE public.e_tickets_promotions IS 'プロモーション系eチケットの定義（割引率/割引額）';
COMMENT ON COLUMN public.e_tickets_promotions.id IS 'ID';
COMMENT ON COLUMN public.e_tickets_promotions.short_name IS '短縮名';
COMMENT ON COLUMN public.e_tickets_promotions.name IS 'eチケット名';
COMMENT ON COLUMN public.e_tickets_promotions.image_url IS '画像URL';
COMMENT ON COLUMN public.e_tickets_promotions.discount_type IS '割引タイプ';
COMMENT ON COLUMN public.e_tickets_promotions.discount_value IS '割引値';
COMMENT ON COLUMN public.e_tickets_promotions.is_birthday_month_only IS '誕生月限定フラグ';
COMMENT ON COLUMN public.e_tickets_promotions.created_at IS '作成日時';

-- ----------------------------------------------------------------
-- e_tickets_special_offers
-- ----------------------------------------------------------------
COMMENT ON TABLE public.e_tickets_special_offers IS '特別オファー系eチケットの定義（特別価格商品）';
COMMENT ON COLUMN public.e_tickets_special_offers.id IS 'ID';
COMMENT ON COLUMN public.e_tickets_special_offers.short_name IS '短縮名';
COMMENT ON COLUMN public.e_tickets_special_offers.name IS 'eチケット名';
COMMENT ON COLUMN public.e_tickets_special_offers.image_url IS '画像URL';
COMMENT ON COLUMN public.e_tickets_special_offers.special_price IS '特別価格';
COMMENT ON COLUMN public.e_tickets_special_offers.target_sku_id IS '対象SKU ID';
COMMENT ON COLUMN public.e_tickets_special_offers.max_quantity_per_order IS '1注文あたりの最大数量';
COMMENT ON COLUMN public.e_tickets_special_offers.created_at IS '作成日時';

-- ----------------------------------------------------------------
-- email_check_rate_limits
-- ----------------------------------------------------------------
COMMENT ON TABLE public.email_check_rate_limits IS 'メールアドレス重複チェックRPCのレート制限。service_role のみアクセス可';
COMMENT ON COLUMN public.email_check_rate_limits.id IS 'ID';
COMMENT ON COLUMN public.email_check_rate_limits.ip_hash IS 'IPハッシュ';
COMMENT ON COLUMN public.email_check_rate_limits.created_at IS '作成日時';

-- ----------------------------------------------------------------
-- orders
-- ----------------------------------------------------------------
COMMENT ON TABLE public.orders IS '注文';
COMMENT ON COLUMN public.orders.id IS 'ID';
COMMENT ON COLUMN public.orders.order_id IS '注文ID';
COMMENT ON COLUMN public.orders.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.orders.order_type IS '注文タイプ';
COMMENT ON COLUMN public.orders.pickup_number IS '受取番号';
COMMENT ON COLUMN public.orders.price_without_tax IS '税抜価格';
COMMENT ON COLUMN public.orders.price_with_tax IS '税込価格';
COMMENT ON COLUMN public.orders.payment_method IS '支払方法';
COMMENT ON COLUMN public.orders.created_at IS '作成日時';
COMMENT ON COLUMN public.orders.updated_at IS '更新日時';
COMMENT ON COLUMN public.orders.provided_status IS '提供ステータス';
COMMENT ON COLUMN public.orders.store_number IS '店舗番号';
COMMENT ON COLUMN public.orders.usage IS '利用区分';

-- ----------------------------------------------------------------
-- orders_archive
-- ----------------------------------------------------------------
COMMENT ON COLUMN public.orders_archive.id IS 'ID';
COMMENT ON COLUMN public.orders_archive.order_id IS '注文ID';
COMMENT ON COLUMN public.orders_archive.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.orders_archive.store_number IS '店舗番号';
COMMENT ON COLUMN public.orders_archive.usage IS '利用区分';
COMMENT ON COLUMN public.orders_archive.order_type IS '注文タイプ';
COMMENT ON COLUMN public.orders_archive.pickup_number IS '受取番号';
COMMENT ON COLUMN public.orders_archive.price_without_tax IS '税抜価格';
COMMENT ON COLUMN public.orders_archive.price_with_tax IS '税込価格';
COMMENT ON COLUMN public.orders_archive.payment_method IS '支払方法';
COMMENT ON COLUMN public.orders_archive.provided_status IS '提供ステータス';
COMMENT ON COLUMN public.orders_archive.created_at IS '作成日時';
COMMENT ON COLUMN public.orders_archive.updated_at IS '更新日時';
COMMENT ON COLUMN public.orders_archive.archived_at IS 'アーカイブ日時';

-- ----------------------------------------------------------------
-- orders_detail
-- ----------------------------------------------------------------
COMMENT ON TABLE public.orders_detail IS '注文明細';
COMMENT ON COLUMN public.orders_detail.id IS 'ID';
COMMENT ON COLUMN public.orders_detail.order_id IS '注文ID';
COMMENT ON COLUMN public.orders_detail.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.orders_detail.product_id IS '商品ID';
COMMENT ON COLUMN public.orders_detail.temperature_type_id IS '温度タイプID';
COMMENT ON COLUMN public.orders_detail.size_id IS 'サイズID';
COMMENT ON COLUMN public.orders_detail.count IS '数量';
COMMENT ON COLUMN public.orders_detail.subtotal_without_tax IS '税抜小計';

-- ----------------------------------------------------------------
-- orders_detail_archive
-- ----------------------------------------------------------------
COMMENT ON COLUMN public.orders_detail_archive.id IS 'ID';
COMMENT ON COLUMN public.orders_detail_archive.order_id IS '注文ID';
COMMENT ON COLUMN public.orders_detail_archive.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.orders_detail_archive.product_id IS '商品ID';
COMMENT ON COLUMN public.orders_detail_archive.temperature_type_id IS '温度タイプID';
COMMENT ON COLUMN public.orders_detail_archive.size_id IS 'サイズID';
COMMENT ON COLUMN public.orders_detail_archive.count IS '数量';
COMMENT ON COLUMN public.orders_detail_archive.subtotal_without_tax IS '税抜小計';
COMMENT ON COLUMN public.orders_detail_archive.archived_at IS 'アーカイブ日時';

-- ----------------------------------------------------------------
-- poc_realtime
-- ----------------------------------------------------------------
COMMENT ON TABLE public.poc_realtime IS 'Supabase Realtime 検証用のPoCテーブル。本番機能では使用しない';
COMMENT ON COLUMN public.poc_realtime.id IS 'ID';
COMMENT ON COLUMN public.poc_realtime.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.poc_realtime.created_at IS '作成日時';

-- ----------------------------------------------------------------
-- pre_signup_users
-- ----------------------------------------------------------------
COMMENT ON TABLE public.pre_signup_users IS '本登録前の仮登録ユーザー';
COMMENT ON COLUMN public.pre_signup_users.id IS 'ID';
COMMENT ON COLUMN public.pre_signup_users.token IS 'トークン';
COMMENT ON COLUMN public.pre_signup_users.email IS 'メールアドレス';
COMMENT ON COLUMN public.pre_signup_users.created_at IS '作成日時';
COMMENT ON COLUMN public.pre_signup_users.expires_at IS '有効期限';

-- ----------------------------------------------------------------
-- prefectures
-- ----------------------------------------------------------------
COMMENT ON TABLE public.prefectures IS '都道府県マスタ';
COMMENT ON COLUMN public.prefectures.id IS 'ID';
COMMENT ON COLUMN public.prefectures.name IS '都道府県名';

-- ----------------------------------------------------------------
-- product_sizes
-- ----------------------------------------------------------------
COMMENT ON TABLE public.product_sizes IS '商品とサイズの関連（価格を保持）';
COMMENT ON COLUMN public.product_sizes.product_id IS '商品ID';
COMMENT ON COLUMN public.product_sizes.size_id IS 'サイズID';
COMMENT ON COLUMN public.product_sizes.price IS '価格';

-- ----------------------------------------------------------------
-- product_temperature_types
-- ----------------------------------------------------------------
COMMENT ON TABLE public.product_temperature_types IS '商品と温度タイプの関連';
COMMENT ON COLUMN public.product_temperature_types.product_id IS '商品ID';
COMMENT ON COLUMN public.product_temperature_types.temperature_type_id IS '温度タイプID';

-- ----------------------------------------------------------------
-- products
-- ----------------------------------------------------------------
COMMENT ON TABLE public.products IS '商品マスタ';
COMMENT ON COLUMN public.products.product_id IS '商品ID';
COMMENT ON COLUMN public.products.product_name IS '商品名';
COMMENT ON COLUMN public.products.category_id IS 'カテゴリID';
COMMENT ON COLUMN public.products.description IS '説明';
COMMENT ON COLUMN public.products.is_active IS '有効フラグ';
COMMENT ON COLUMN public.products.created_at IS '作成日時';
COMMENT ON COLUMN public.products.updated_at IS '更新日時';
COMMENT ON COLUMN public.products.product_image_path IS '商品画像パス';
COMMENT ON COLUMN public.products.display_order IS '表示順';
COMMENT ON COLUMN public.products.sale_type IS '販売タイプ';

-- ----------------------------------------------------------------
-- sizes
-- ----------------------------------------------------------------
COMMENT ON TABLE public.sizes IS 'サイズマスタ';
COMMENT ON COLUMN public.sizes.size_id IS 'サイズID';
COMMENT ON COLUMN public.sizes.size_name IS 'サイズ名';
COMMENT ON COLUMN public.sizes.size_description IS 'サイズ説明';

-- ----------------------------------------------------------------
-- staff
-- ----------------------------------------------------------------
COMMENT ON TABLE public.staff IS 'スタッフマスタ';
COMMENT ON COLUMN public.staff.staff_number IS 'スタッフ番号';
COMMENT ON COLUMN public.staff.staff_name IS 'スタッフ名';
COMMENT ON COLUMN public.staff.email IS 'メールアドレス';
COMMENT ON COLUMN public.staff.phone IS '電話番号';
COMMENT ON COLUMN public.staff.employment_type IS '雇用形態';
COMMENT ON COLUMN public.staff.hire_date IS '入社日';
COMMENT ON COLUMN public.staff.termination_date IS '退職日';
COMMENT ON COLUMN public.staff.is_active IS '有効フラグ';
COMMENT ON COLUMN public.staff.created_at IS '作成日時';
COMMENT ON COLUMN public.staff.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- staff_schedules
-- ----------------------------------------------------------------
COMMENT ON TABLE public.staff_schedules IS 'スタッフの日次シフトスケジュール';
COMMENT ON COLUMN public.staff_schedules.id IS 'ID';
COMMENT ON COLUMN public.staff_schedules.date IS '日付';
COMMENT ON COLUMN public.staff_schedules.staff_number IS 'スタッフ番号';
COMMENT ON COLUMN public.staff_schedules.store_number IS '店舗番号';
COMMENT ON COLUMN public.staff_schedules.period_1 IS '第1時間帯勤務';
COMMENT ON COLUMN public.staff_schedules.period_2 IS '第2時間帯勤務';
COMMENT ON COLUMN public.staff_schedules.period_3 IS '第3時間帯勤務';
COMMENT ON COLUMN public.staff_schedules.period_4 IS '第4時間帯勤務';
COMMENT ON COLUMN public.staff_schedules.period_5 IS '第5時間帯勤務';
COMMENT ON COLUMN public.staff_schedules.created_at IS '作成日時';
COMMENT ON COLUMN public.staff_schedules.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- star_acquisitions
-- ----------------------------------------------------------------
COMMENT ON TABLE public.star_acquisitions IS 'スター獲得履歴';
COMMENT ON COLUMN public.star_acquisitions.id IS 'ID';
COMMENT ON COLUMN public.star_acquisitions.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.star_acquisitions.order_id IS '注文ID';
COMMENT ON COLUMN public.star_acquisitions.category IS 'カテゴリ';
COMMENT ON COLUMN public.star_acquisitions.acquired_points IS '獲得ポイント';
COMMENT ON COLUMN public.star_acquisitions.created_at IS '作成日時';
COMMENT ON COLUMN public.star_acquisitions.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- star_acquisitions_archive
-- ----------------------------------------------------------------
COMMENT ON COLUMN public.star_acquisitions_archive.id IS 'ID';
COMMENT ON COLUMN public.star_acquisitions_archive.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.star_acquisitions_archive.order_id IS '注文ID';
COMMENT ON COLUMN public.star_acquisitions_archive.category IS 'カテゴリ';
COMMENT ON COLUMN public.star_acquisitions_archive.acquired_points IS '獲得ポイント';
COMMENT ON COLUMN public.star_acquisitions_archive.created_at IS '作成日時';
COMMENT ON COLUMN public.star_acquisitions_archive.updated_at IS '更新日時';
COMMENT ON COLUMN public.star_acquisitions_archive.archived_at IS 'アーカイブ日時';

-- ----------------------------------------------------------------
-- star_aggregations
-- ----------------------------------------------------------------
COMMENT ON TABLE public.star_aggregations IS 'ユーザー・年月ごとのスター集計';
COMMENT ON COLUMN public.star_aggregations.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.star_aggregations.target_year_month IS '対象年月';
COMMENT ON COLUMN public.star_aggregations.total_points IS '合計ポイント';
COMMENT ON COLUMN public.star_aggregations.expiration_datetime IS '有効期限';
COMMENT ON COLUMN public.star_aggregations.created_at IS '作成日時';
COMMENT ON COLUMN public.star_aggregations.updated_at IS '更新日時';
COMMENT ON COLUMN public.star_aggregations.expiration_flag IS '期限切れフラグ';

-- ----------------------------------------------------------------
-- star_rewards_exchange_items
-- ----------------------------------------------------------------
COMMENT ON TABLE public.star_rewards_exchange_items IS 'スター交換商品マスタ';
COMMENT ON COLUMN public.star_rewards_exchange_items.id IS 'ID';
COMMENT ON COLUMN public.star_rewards_exchange_items.short_name IS '短縮名';
COMMENT ON COLUMN public.star_rewards_exchange_items.name IS '商品名';
COMMENT ON COLUMN public.star_rewards_exchange_items.image_url IS '画像URL';
COMMENT ON COLUMN public.star_rewards_exchange_items.points IS '必要ポイント';

-- ----------------------------------------------------------------
-- star_usage
-- ----------------------------------------------------------------
COMMENT ON TABLE public.star_usage IS 'スター使用履歴';
COMMENT ON COLUMN public.star_usage.id IS 'ID';
COMMENT ON COLUMN public.star_usage.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.star_usage.order_id IS '注文ID';
COMMENT ON COLUMN public.star_usage.exchange_item_id IS '交換商品ID';
COMMENT ON COLUMN public.star_usage.point_used IS '使用ポイント';
COMMENT ON COLUMN public.star_usage.created_at IS '作成日時';
COMMENT ON COLUMN public.star_usage.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- star_usage_archive
-- ----------------------------------------------------------------
COMMENT ON COLUMN public.star_usage_archive.id IS 'ID';
COMMENT ON COLUMN public.star_usage_archive.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.star_usage_archive.order_id IS '注文ID';
COMMENT ON COLUMN public.star_usage_archive.exchange_item_id IS '交換商品ID';
COMMENT ON COLUMN public.star_usage_archive.point_used IS '使用ポイント';
COMMENT ON COLUMN public.star_usage_archive.created_at IS '作成日時';
COMMENT ON COLUMN public.star_usage_archive.updated_at IS '更新日時';
COMMENT ON COLUMN public.star_usage_archive.archived_at IS 'アーカイブ日時';

-- ----------------------------------------------------------------
-- store_profiles
-- ----------------------------------------------------------------
COMMENT ON TABLE public.store_profiles IS '店舗の詳細プロフィール';
COMMENT ON COLUMN public.store_profiles.id IS 'ID';
COMMENT ON COLUMN public.store_profiles.store_number IS '店舗番号';
COMMENT ON COLUMN public.store_profiles.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.store_profiles.created_at IS '作成日時';
COMMENT ON COLUMN public.store_profiles.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- stores
-- ----------------------------------------------------------------
COMMENT ON TABLE public.stores IS '店舗マスタ';
COMMENT ON COLUMN public.stores.id IS 'ID';
COMMENT ON COLUMN public.stores.store_number IS '店舗番号';
COMMENT ON COLUMN public.stores.store_name IS '店舗名';
COMMENT ON COLUMN public.stores.prefecture_id IS '都道府県ID';
COMMENT ON COLUMN public.stores.address IS '住所';
COMMENT ON COLUMN public.stores.opening_date IS 'オープン日';
COMMENT ON COLUMN public.stores.closing_date IS '閉店日';
COMMENT ON COLUMN public.stores.created_at IS '作成日時';
COMMENT ON COLUMN public.stores.updated_at IS '更新日時';
COMMENT ON COLUMN public.stores.closing_time IS '閉店時間';
COMMENT ON COLUMN public.stores.opening_time IS '開店時間';
COMMENT ON COLUMN public.stores.latitude IS '緯度';
COMMENT ON COLUMN public.stores.longitude IS '経度';
COMMENT ON COLUMN public.stores.is_drive_thru_available IS 'ドライブスルー利用可能';

-- ----------------------------------------------------------------
-- temperature_types
-- ----------------------------------------------------------------
COMMENT ON TABLE public.temperature_types IS '温度タイプ（ホット/アイス等）マスタ';
COMMENT ON COLUMN public.temperature_types.temperature_type_id IS '温度タイプID';
COMMENT ON COLUMN public.temperature_types.type_name IS 'タイプ名';

-- ----------------------------------------------------------------
-- user_fcm_tokens
-- ----------------------------------------------------------------
COMMENT ON TABLE public.user_fcm_tokens IS 'ユーザーの端末ごとのFCMトークン';
COMMENT ON COLUMN public.user_fcm_tokens.fcm_token IS 'FCMトークン';
COMMENT ON COLUMN public.user_fcm_tokens.is_notify IS '通知設定';
COMMENT ON COLUMN public.user_fcm_tokens.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.user_fcm_tokens.device_id IS 'デバイスID';
COMMENT ON COLUMN public.user_fcm_tokens.device_name IS 'デバイス名';
COMMENT ON COLUMN public.user_fcm_tokens.created_at IS '作成日時';
COMMENT ON COLUMN public.user_fcm_tokens.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- user_mail_settings
-- ----------------------------------------------------------------
COMMENT ON TABLE public.user_mail_settings IS 'ユーザーのメール受信設定';
COMMENT ON COLUMN public.user_mail_settings.id IS 'ID';
COMMENT ON COLUMN public.user_mail_settings.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.user_mail_settings.is_send_related_rewards IS 'リワード関連メール送信設定';
COMMENT ON COLUMN public.user_mail_settings.is_send_advance_product_announce IS '商品先行告知メール送信設定';
COMMENT ON COLUMN public.user_mail_settings.is_html_mail IS 'HTMLメール設定';
COMMENT ON COLUMN public.user_mail_settings.created_at IS '作成日時';
COMMENT ON COLUMN public.user_mail_settings.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- user_nickname
-- ----------------------------------------------------------------
COMMENT ON TABLE public.user_nickname IS 'ユーザーのニックネーム';
COMMENT ON COLUMN public.user_nickname.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.user_nickname.nick_name IS 'ニックネーム';

-- ----------------------------------------------------------------
-- user_profile_details
-- ----------------------------------------------------------------
COMMENT ON TABLE public.user_profile_details IS 'ユーザーのプロフィール詳細';
COMMENT ON COLUMN public.user_profile_details.id IS 'ID';
COMMENT ON COLUMN public.user_profile_details.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.user_profile_details.birthday IS '生年月日';
COMMENT ON COLUMN public.user_profile_details.sex IS '性別';
COMMENT ON COLUMN public.user_profile_details.tele_num IS '電話番号';
COMMENT ON COLUMN public.user_profile_details.postal_code IS '郵便番号';
COMMENT ON COLUMN public.user_profile_details.prefecture_id IS '都道府県ID';
COMMENT ON COLUMN public.user_profile_details.address1 IS '住所1';
COMMENT ON COLUMN public.user_profile_details.address2 IS '住所2';
COMMENT ON COLUMN public.user_profile_details.created_at IS '作成日時';
COMMENT ON COLUMN public.user_profile_details.updated_at IS '更新日時';

-- ----------------------------------------------------------------
-- user_tickets
-- ----------------------------------------------------------------
COMMENT ON TABLE public.user_tickets IS 'ユーザーが保有するeチケットの実体';
COMMENT ON COLUMN public.user_tickets.id IS 'ID';
COMMENT ON COLUMN public.user_tickets.user_id IS 'ユーザーID';
COMMENT ON COLUMN public.user_tickets.ticket_type IS 'チケットタイプ';
COMMENT ON COLUMN public.user_tickets.definition_id IS '定義ID';
COMMENT ON COLUMN public.user_tickets.expired_at IS '有効期限';
COMMENT ON COLUMN public.user_tickets.is_used IS '利用済フラグ';
COMMENT ON COLUMN public.user_tickets.created_at IS '作成日時';
COMMENT ON COLUMN public.user_tickets.updated_at IS '更新日時';
COMMENT ON COLUMN public.user_tickets.used_at IS '利用日時';
-- ----------------------------------------------------------------
-- mv_products_catalog (Materialized View)
-- ----------------------------------------------------------------
COMMENT ON MATERIALIZED VIEW public.mv_products_catalog IS
  '商品カタログの結合済みビュー。products / categories / product_sizes / sizes / product_temperature_types / temperature_types を JOIN した読み取り専用スナップショット（更新手順は mv_products_catalog_guide.md）';

COMMENT ON COLUMN public.mv_products_catalog.product_id IS '商品ID';
COMMENT ON COLUMN public.mv_products_catalog.product_name IS '商品名';
COMMENT ON COLUMN public.mv_products_catalog.category_id IS 'カテゴリID';
COMMENT ON COLUMN public.mv_products_catalog.category_name IS 'カテゴリ名';
COMMENT ON COLUMN public.mv_products_catalog.description IS '説明';
COMMENT ON COLUMN public.mv_products_catalog.product_image_path IS '商品画像パス';
COMMENT ON COLUMN public.mv_products_catalog.sale_type IS '販売タイプ';
COMMENT ON COLUMN public.mv_products_catalog.display_order IS '表示順';
COMMENT ON COLUMN public.mv_products_catalog.size_id IS 'サイズID';
COMMENT ON COLUMN public.mv_products_catalog.size_name IS 'サイズ名';
COMMENT ON COLUMN public.mv_products_catalog.price IS '価格';
COMMENT ON COLUMN public.mv_products_catalog.temperature_type_id IS '温度タイプID';
COMMENT ON COLUMN public.mv_products_catalog.temperature_type_name IS '温度タイプ名';
