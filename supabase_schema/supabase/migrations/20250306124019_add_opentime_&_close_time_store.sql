alter table "public"."stores" add column "closing_time" time without time zone not null default '21:00:00'::time without time zone;

alter table "public"."stores" add column "opening_time" time without time zone not null default '09:00:00'::time without time zone;

alter table "public"."stores" enable row level security;

create policy "read_only_stores"
on "public"."stores"
as permissive
for select
to public
using (true);



