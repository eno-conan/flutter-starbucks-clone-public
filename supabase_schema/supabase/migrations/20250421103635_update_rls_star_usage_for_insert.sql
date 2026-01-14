create policy "authenticated user insert star_usage"
on "public"."star_usage"
as permissive
for insert
to authenticated
with check (true);



