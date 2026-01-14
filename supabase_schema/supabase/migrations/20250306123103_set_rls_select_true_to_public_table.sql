alter table "public"."categories" enable row level security;

alter table "public"."product_sizes" enable row level security;

alter table "public"."product_temperature_types" enable row level security;

alter table "public"."products" enable row level security;

alter table "public"."sizes" enable row level security;

alter table "public"."temperature_types" enable row level security;

create policy "read_only_categories"
on "public"."categories"
as permissive
for select
to public
using (true);


create policy "read_only_product_sizes"
on "public"."product_sizes"
as permissive
for select
to public
using (true);


create policy "read_only_product_temperature_types"
on "public"."product_temperature_types"
as permissive
for select
to public
using (true);


create policy "read_only_products"
on "public"."products"
as permissive
for select
to public
using (true);


create policy "read_only_sizes"
on "public"."sizes"
as permissive
for select
to public
using (true);


create policy "read_only_temperature_types"
on "public"."temperature_types"
as permissive
for select
to public
using (true);



