-- Issue#544: データアーカイブ戦略 - アーカイブテーブルの作成
-- 保持期間を超えたデータをアーカイブ保存するためのテーブル群
-- アーカイブテーブルはFKなし・RLS有効・service_roleのみアクセス可能

-- ----------------------------------------------------------------
-- orders_archive
-- ----------------------------------------------------------------
CREATE TABLE "public"."orders_archive" (
    "id"                uuid                     NOT NULL,
    "order_id"          text                     NOT NULL,
    "user_id"           uuid                     NOT NULL,
    "store_number"      character(4)             NOT NULL,
    "usage"             smallint                 NOT NULL,
    "order_type"        smallint                 NOT NULL,
    "pickup_number"     text                     NOT NULL,
    "price_without_tax" integer                  NOT NULL,
    "price_with_tax"    integer                  NOT NULL,
    "payment_method"    text                     NOT NULL,
    "provided_status"   text                     NOT NULL DEFAULT '0',
    "created_at"        timestamp with time zone NOT NULL,
    "updated_at"        timestamp with time zone NOT NULL,
    "archived_at"       timestamp with time zone NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.orders_archive
    IS '注文履歴アーカイブ: 18ヶ月以上前のordersデータを保存。マーケティング分析用途。';

CREATE UNIQUE INDEX orders_archive_pkey
    ON public.orders_archive USING btree (id);
ALTER TABLE "public"."orders_archive"
    ADD CONSTRAINT "orders_archive_pkey" PRIMARY KEY USING INDEX "orders_archive_pkey";

CREATE UNIQUE INDEX orders_archive_order_id_key
    ON public.orders_archive USING btree (order_id);
ALTER TABLE "public"."orders_archive"
    ADD CONSTRAINT "orders_archive_order_id_key" UNIQUE USING INDEX "orders_archive_order_id_key";

CREATE INDEX idx_orders_archive_user_id
    ON public.orders_archive USING btree (user_id);
CREATE INDEX idx_orders_archive_created_at
    ON public.orders_archive USING btree (created_at);
CREATE INDEX idx_orders_archive_archived_at
    ON public.orders_archive USING btree (archived_at);

ALTER TABLE "public"."orders_archive" ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT ON TABLE "public"."orders_archive" TO "service_role";

-- ----------------------------------------------------------------
-- orders_detail_archive
-- ----------------------------------------------------------------
CREATE TABLE "public"."orders_detail_archive" (
    "id"                   uuid    NOT NULL,
    "order_id"             text,
    "user_id"              uuid,
    "product_id"           integer,
    "temperature_type_id"  integer,
    "size_id"              integer,
    "count"                integer NOT NULL,
    "subtotal_without_tax" integer NOT NULL,
    "archived_at"          timestamp with time zone NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.orders_detail_archive
    IS '注文詳細履歴アーカイブ: ordersと連動してアーカイブ。';

CREATE UNIQUE INDEX orders_detail_archive_pkey
    ON public.orders_detail_archive USING btree (id);
ALTER TABLE "public"."orders_detail_archive"
    ADD CONSTRAINT "orders_detail_archive_pkey" PRIMARY KEY USING INDEX "orders_detail_archive_pkey";

CREATE INDEX idx_orders_detail_archive_order_id
    ON public.orders_detail_archive USING btree (order_id);

ALTER TABLE "public"."orders_detail_archive" ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT ON TABLE "public"."orders_detail_archive" TO "service_role";

-- ----------------------------------------------------------------
-- star_acquisitions_archive
-- ----------------------------------------------------------------
CREATE TABLE "public"."star_acquisitions_archive" (
    "id"              uuid                     NOT NULL,
    "user_id"         uuid                     NOT NULL,
    "order_id"        text                     NOT NULL,
    "category"        smallint                 NOT NULL,
    "acquired_points" numeric(10,1)            NOT NULL,
    "created_at"      timestamp with time zone NOT NULL,
    "updated_at"      timestamp with time zone NOT NULL,
    "archived_at"     timestamp with time zone NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.star_acquisitions_archive
    IS 'スター取得履歴アーカイブ: 18ヶ月以上前のstar_acquisitionsデータを保存。';

CREATE UNIQUE INDEX star_acquisitions_archive_pkey
    ON public.star_acquisitions_archive USING btree (id);
ALTER TABLE "public"."star_acquisitions_archive"
    ADD CONSTRAINT "star_acquisitions_archive_pkey" PRIMARY KEY USING INDEX "star_acquisitions_archive_pkey";

CREATE INDEX idx_star_acquisitions_archive_user_id
    ON public.star_acquisitions_archive USING btree (user_id);
CREATE INDEX idx_star_acquisitions_archive_created_at
    ON public.star_acquisitions_archive USING btree (created_at);

ALTER TABLE "public"."star_acquisitions_archive" ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT ON TABLE "public"."star_acquisitions_archive" TO "service_role";

-- ----------------------------------------------------------------
-- star_usage_archive
-- ----------------------------------------------------------------
CREATE TABLE "public"."star_usage_archive" (
    "id"               uuid                     NOT NULL,
    "user_id"          uuid                     NOT NULL,
    "order_id"         text,
    "exchange_item_id" integer,
    "point_used"       numeric(10,1)            NOT NULL,
    "created_at"       timestamp with time zone NOT NULL,
    "updated_at"       timestamp with time zone NOT NULL,
    "archived_at"      timestamp with time zone NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.star_usage_archive
    IS 'スター使用履歴アーカイブ: 18ヶ月以上前のstar_usageデータを保存。';

CREATE UNIQUE INDEX star_usage_archive_pkey
    ON public.star_usage_archive USING btree (id);
ALTER TABLE "public"."star_usage_archive"
    ADD CONSTRAINT "star_usage_archive_pkey" PRIMARY KEY USING INDEX "star_usage_archive_pkey";

CREATE INDEX idx_star_usage_archive_user_id
    ON public.star_usage_archive USING btree (user_id);
CREATE INDEX idx_star_usage_archive_created_at
    ON public.star_usage_archive USING btree (created_at);

ALTER TABLE "public"."star_usage_archive" ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT ON TABLE "public"."star_usage_archive" TO "service_role";
