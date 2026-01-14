create type "public"."sale_type_enum" as enum ('regular', 'seasonal', 'limited');

alter table "public"."products" add column "display_order" integer default 999;

alter table "public"."products" add column "sale_type" sale_type_enum default 'regular'::sale_type_enum;

CREATE INDEX idx_display_order ON public.products USING btree (display_order, category_id);


